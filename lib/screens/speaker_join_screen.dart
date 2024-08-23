import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/screens/ils_screen.dart';
import 'package:videosdk_hls_flutter_example/utils/api.dart';

import '../constants/colors.dart';
import '../utils/spacer.dart';
import '../utils/toast.dart';

// Join Screen
class SpeakerJoinScreen extends StatefulWidget {
  final bool isCreateMeeting;
  const SpeakerJoinScreen({Key? key, required this.isCreateMeeting})
      : super(key: key);

  @override
  State<SpeakerJoinScreen> createState() => _SpeakerJoinScreenState();
}

class _SpeakerJoinScreenState extends State<SpeakerJoinScreen> {
  String _token = "";

  // Control Status
  bool isMicOn = true;
  bool isCameraOn = true;

  CustomTrack? cameraTrack;
  RTCVideoRenderer? cameraRenderer;

  TextEditingController meetingIdTextController = TextEditingController();
  TextEditingController nameTextController = TextEditingController();
  @override
  void initState() {
    initCameraPreview();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await fetchToken(context);
      setState(() {
        _token = token;
      });
      if (widget.isCreateMeeting) {
        final meetingId = await createMeeting(token);
        setState(() {
          meetingIdTextController.value = TextEditingValue(text: meetingId);
        });
      }
    });
  }

  @override
  setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text(
          widget.isCreateMeeting ? "Create Meeting" : "Join as a speaker",
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Camera Preview
              SizedBox(
                height: 300,
                width: 200,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (cameraRenderer != null)
                      SizedBox(
                        height: 300,
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: RTCVideoView(
                            cameraRenderer as RTCVideoRenderer,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 16,

                      // Meeting ActionBar
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Mic Action Button
                            ElevatedButton(
                              onPressed: () => setState(
                                () => isMicOn = !isMicOn,
                              ),
                              child: Icon(isMicOn ? Icons.mic : Icons.mic_off,
                                  color: isMicOn ? grey : Colors.white),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: isMicOn ? Colors.white : red,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (isCameraOn) {
                                  disposeCameraPreview();
                                } else {
                                  initCameraPreview();
                                }
                                setState(() => isCameraOn = !isCameraOn);
                              },
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                backgroundColor:
                                    isCameraOn ? Colors.white : red,
                                padding: const EdgeInsets.all(12),
                              ),
                              child: Icon(
                                isCameraOn
                                    ? Icons.videocam
                                    : Icons.videocam_off,
                                color: isCameraOn ? grey : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(36.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.isCreateMeeting)
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: black750),
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Meeting code: ${meetingIdTextController.text}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 16),
                            ),
                            GestureDetector(
                              child: const Padding(
                                padding: EdgeInsets.fromLTRB(8, 0, 0, 0),
                                child: Icon(
                                  Icons.copy,
                                  size: 16,
                                ),
                              ),
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                    text: meetingIdTextController.text));
                                showSnackBarMessage(
                                    message: "Meeting ID has been copied.",
                                    context: context);
                              },
                            ),
                          ],
                        ),
                      ),
                    if (widget.isCreateMeeting) const VerticalSpacer(16),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: black750),
                      child: TextField(
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                        controller: nameTextController,
                        decoration: const InputDecoration(
                            hintText: "Enter your name",
                            hintStyle: TextStyle(
                              color: textGray,
                            ),
                            border: InputBorder.none),
                      ),
                    ),
                    const VerticalSpacer(16),
                    if (!widget.isCreateMeeting)
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: black750),
                        child: TextField(
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          controller: meetingIdTextController,
                          decoration: const InputDecoration(
                              hintText: "Enter meeting code",
                              hintStyle: TextStyle(
                                color: textGray,
                              ),
                              border: InputBorder.none),
                        ),
                      ),
                    if (!widget.isCreateMeeting) const VerticalSpacer(16),
                    MaterialButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: purple,
                        child: Text(
                            widget.isCreateMeeting
                                ? "Create Meeting"
                                : "Join as a speaker",
                            style: const TextStyle(fontSize: 16)),
                        onPressed: () => {joinMeeting()}),
                  ],
                ),
              )
            ],
          ),
        ),
      )),
    );
  }

  void initCameraPreview() async {
    CustomTrack? track = await VideoSDK.createCameraVideoTrack();
    RTCVideoRenderer render = RTCVideoRenderer();
    await render.initialize();
    render.setSrcObject(stream: track?.mediaStream);
    setState(() {
      cameraTrack = track;
      cameraRenderer = render;
    });
  }

  void disposeCameraPreview() {
    cameraTrack?.dispose();
    setState(() {
      cameraRenderer = null;
      cameraTrack = null;
    });
  }

  Future<void> joinMeeting() async {
    if (meetingIdTextController.text.isEmpty) {
      showSnackBarMessage(
          message: "Please enter Valid Meeting ID", context: context);
      return;
    }
    if (nameTextController.text.isEmpty) {
      showSnackBarMessage(message: "Please enter Name", context: context);
      return;
    }
    String meetingId = meetingIdTextController.text;
    String name = nameTextController.text;
    var validMeeting = await validateMeeting(_token, meetingId);
    if (context.mounted) {
      if (validMeeting) {
        disposeCameraPreview();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ILSScreen(
              token: _token,
              meetingId: meetingId,
              displayName: name,
              micEnabled: isMicOn,
              camEnabled: isCameraOn,
              mode: Mode.CONFERENCE,
            ),
          ),
        );
      } else {
        showSnackBarMessage(message: "Invalid Meeting ID", context: context);
      }
    }
  }

  @override
  void dispose() {
    cameraTrack?.dispose();
    super.dispose();
  }
}
