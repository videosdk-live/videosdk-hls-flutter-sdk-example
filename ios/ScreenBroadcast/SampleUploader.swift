//
//  SampleUploader.swift
//  ScreenBroadcastiOS
//
//  Created by Parth Asodariya on 23/06/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import ReplayKit
import CoreImage

private enum Constants {
    static let bufferMaxLength = 10240
}

class SampleUploader {
    
    // `options: nil` leaves `cacheIntermediates` on, so CoreImage keeps render
    // intermediates alive between frames. Inside a broadcast extension's hard
    // 50 MB budget that reads as a slow leak: memory climbs until jetsam kills
    // the extension mid-share. This context holds nothing between frames.
    private static var imageContext = CIContext(options: [.cacheIntermediates: false])
    
    @Atomic private var isReady = false
    private var connection: SocketConnection
  
    private var dataToSend: Data?
    private var byteIndex = 0
  
    private let serialQueue: DispatchQueue
    
    init(connection: SocketConnection) {
        self.connection = connection
        self.serialQueue = DispatchQueue(label: "org.videosdk.broadcast.sampleUploader")
      
        setupConnection()
    }
  
    @discardableResult func send(sample buffer: CMSampleBuffer) -> Bool {
        guard isReady else {
            return false
        }
        
        isReady = false

        // Scope the encode. `prepare` builds a full-frame bitmap and a JPEG
        // CFData per call, both autoreleased; with no pool they accumulate
        // until the thread's own pool drains, which is what pushes this
        // extension past 50 MB roughly 20-30s into a share.
        dataToSend = autoreleasepool { prepare(sample: buffer) }
        byteIndex = 0

        serialQueue.async { [weak self] in
            self?.sendDataChunk()
        }
        
        return true
    }
}

private extension SampleUploader {
    
    func setupConnection() {
        connection.didOpen = { [weak self] in
            self?.isReady = true
        }
        connection.streamHasSpaceAvailable = { [weak self] in
            self?.serialQueue.async {
                if let success = self?.sendDataChunk() {
                    self?.isReady = !success
                }
            }
        }
    }
    
    @discardableResult func sendDataChunk() -> Bool {
        guard let dataToSend else {
            return false
        }

        var bytesLeft = dataToSend.count - byteIndex
        var length = bytesLeft > Constants.bufferMaxLength ? Constants.bufferMaxLength : bytesLeft

        length = dataToSend[byteIndex ..< (byteIndex + length)].withUnsafeBytes {
            guard let ptr = $0.bindMemory(to: UInt8.self).baseAddress else {
                return 0
            }

            return connection.writeToStream(buffer: ptr, maxLength: length)
        }

        if length > 0 {
            byteIndex += length
            bytesLeft -= length

            if bytesLeft == 0 {
                self.dataToSend = nil
                byteIndex = 0
            }
        } else {
            print("DEBUG::writeBufferToStream failure")
        }

        return true
    }

    func prepare(sample buffer: CMSampleBuffer) -> Data? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            print("DEBUG::image buffer not available")
            return nil
        }

        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)

        // ReplayKit hands over full-resolution frames — ~12 MB of BGRA on a
        // modern iPhone. Encoding at native size is the main reason this
        // extension runs out of its 50 MB allowance. Shrink the long edge.
        //
        // The factor has to be an integer: the width/height advertised just
        // below divide by `Int(scaleFactor)`, and `SocketConnectionFrameReader`
        // drops any frame whose decoded image is smaller than the geometry its
        // header claims. An integer keeps the two in step — flooring the header
        // leaves the image a hair larger, which satisfies that check. A
        // fractional factor would truncate to 1 here and desynchronise them.
        let maxLongEdge = 1280
        var integerScale = 1
        while max(CVPixelBufferGetWidth(imageBuffer),
                  CVPixelBufferGetHeight(imageBuffer)) / integerScale > maxLongEdge {
            integerScale += 1
        }
        let scaleFactor = Double(integerScale)
        let width = CVPixelBufferGetWidth(imageBuffer) / Int(scaleFactor)
        let height = CVPixelBufferGetHeight(imageBuffer) / Int(scaleFactor)

        let orientation = CMGetAttachment(buffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil)?.uintValue ?? 0

        let scaleTransform = CGAffineTransform(scaleX: CGFloat(1.0 / scaleFactor), y: CGFloat(1.0 / scaleFactor))
        let bufferData = jpegData(from: imageBuffer, scale: scaleTransform)

        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)

        guard let messageData = bufferData else {
            print("DEBUG::corrupted image buffer")
            return nil
        }

        let httpResponse = CFHTTPMessageCreateResponse(nil, 200, nil, kCFHTTPVersion1_1).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(httpResponse, "Content-Length" as CFString, String(messageData.count) as CFString)
        CFHTTPMessageSetHeaderFieldValue(httpResponse, "Buffer-Width" as CFString, String(width) as CFString)
        CFHTTPMessageSetHeaderFieldValue(httpResponse, "Buffer-Height" as CFString, String(height) as CFString)
        CFHTTPMessageSetHeaderFieldValue(httpResponse, "Buffer-Orientation" as CFString, String(orientation) as CFString)

        CFHTTPMessageSetBody(httpResponse, messageData as CFData)

        let serializedMessage = CFHTTPMessageCopySerializedMessage(httpResponse)?.takeRetainedValue() as Data?

        return serializedMessage
    }

    func jpegData(from buffer: CVPixelBuffer, scale scaleTransform: CGAffineTransform) -> Data? {
        let image = CIImage(cvPixelBuffer: buffer).transformed(by: scaleTransform)

        guard let colorSpace = image.colorSpace else {
            return nil
        }

        // 1.0 means "barely compress", and screen content (sharp text and UI
        // edges) is the worst case for JPEG — full-quality frames ran to several
        // MB each. 0.6 is visually indistinguishable for a shared screen at a
        // fraction of the bytes and the transient allocation.
        let options: [CIImageRepresentationOption: Float] = [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.6]

        return SampleUploader.imageContext.jpegRepresentation(of: image, colorSpace: colorSpace, options: options)
    }
}
