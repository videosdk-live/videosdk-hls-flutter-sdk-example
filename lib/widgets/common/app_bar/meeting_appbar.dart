import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/utils/api.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';
import 'package:videosdk_hls_flutter_example/utils/toast.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/app_bar/hls_indicator.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/app_bar/recording_indicator.dart';

class MeetingAppBar extends StatefulWidget {
  final String token;
  final Room meeting;
  final String recordingState;
  final String hlsState;
  final bool isFullScreen;
  const MeetingAppBar(
      {Key? key,
      required this.meeting,
      required this.token,
      required this.isFullScreen,
      required this.recordingState,
      required this.hlsState})
      : super(key: key);

  @override
  State<MeetingAppBar> createState() => MeetingAppBarState();
}

class MeetingAppBarState extends State<MeetingAppBar> {
  Duration? elapsedTime;
  Timer? sessionTimer;

  List<MediaDeviceInfo> cameras = [];

  @override
  void initState() {
    startTimer();
    // Holds available cameras info
    cameras = widget.meeting.getCameras();
    super.initState();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState: !widget.isFullScreen
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        secondChild: const SizedBox.shrink(),
        firstChild: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
          child: Row(
            children: [
              if (widget.recordingState == "RECORDING_STARTING" ||
                  widget.recordingState == "RECORDING_STOPPING" ||
                  widget.recordingState == "RECORDING_STARTED")
                RecordingIndicator(recordingState: widget.recordingState),
              if (widget.recordingState == "RECORDING_STARTING" ||
                  widget.recordingState == "RECORDING_STOPPING" ||
                  widget.recordingState == "RECORDING_STARTED")
                const HorizontalSpacer(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.meeting.id,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
                            Clipboard.setData(
                                ClipboardData(text: widget.meeting.id));
                            showSnackBarMessage(
                                message: "Meeting ID has been copied.",
                                context: context);
                          },
                        ),
                      ],
                    ),
                    // VerticalSpacer(),
                    Text(
                      elapsedTime == null
                          ? "00:00:00"
                          : elapsedTime.toString().split(".").first,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: black400),
                    )
                  ],
                ),
              ),
              MaterialButton(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        color: red),
                    padding: EdgeInsets.all(8),
                    child: Text(widget.hlsState == "HLS_STOPPED"
                        ? "Go Live"
                        : widget.hlsState == "HLS_STARTING"
                            ? "Starting Live"
                            : widget.hlsState == "HLS_STARTED"
                                ? "Live"
                                : "Stopping Live"),
                  ),
                  onPressed: () {
                    if (widget.hlsState == "HLS_STOPPING") {
                      showSnackBarMessage(
                          message: "HLS is in stopping state",
                          context: context);
                    } else if (widget.hlsState == "HLS_STARTED") {
                      widget.meeting.stopHls();
                    } else if (widget.hlsState == "HLS_STARTING") {
                      showSnackBarMessage(
                          message: "HLS is in starting state",
                          context: context);
                    } else {
                      Map<String, dynamic> config = {
                        'layout': {
                          "type": "SPOTLIGHT",
                          "priority": "PIN",
                          "gridSize": "4",
                        },
                        'theme': "DARK",
                        'mode': "video-and-audio",
                        'orientation': "landscape",
                        'quality': "high",
                      };
                      widget.meeting.startHls(config: config);
                    }
                  }),
              // IconButton(
              //   icon: SvgPicture.asset(
              //     "assets/ic_switch_camera.svg",
              //     height: 24,
              //     width: 24,
              //   ),
              //   onPressed: () {
              //     MediaDeviceInfo newCam = cameras.firstWhere((camera) =>
              //         camera.deviceId != widget.meeting.selectedCamId);
              //     widget.meeting.changeCam(newCam.deviceId);
              //   },
              // ),
            ],
          ),
        ));
  }

  Future<void> startTimer() async {
    dynamic session = await fetchSession(widget.token, widget.meeting.id);
    DateTime sessionStartTime = DateTime.parse(session['start']);
    final difference = DateTime.now().difference(sessionStartTime);

    setState(() {
      elapsedTime = difference;
      sessionTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          setState(() {
            elapsedTime = Duration(
                seconds: elapsedTime != null ? elapsedTime!.inSeconds + 1 : 0);
          });
        },
      );
    });
    // log("session start time" + session.data[0].start.toString());
  }

  @override
  void dispose() {
    if (sessionTimer != null) {
      sessionTimer!.cancel();
    }
    super.dispose();
  }
}
