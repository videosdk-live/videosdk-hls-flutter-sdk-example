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
import 'package:touch_ripple_effect/touch_ripple_effect.dart';
import 'package:videosdk_hls_flutter_example/widgets/speaker/participant_list/participant_list.dart';

class SpeakerAppBar extends StatefulWidget {
  final String token;
  final Room meeting;
  final bool isFullScreen;
  const SpeakerAppBar(
      {Key? key,
      required this.meeting,
      required this.token,
      required this.isFullScreen})
      : super(key: key);

  @override
  State<SpeakerAppBar> createState() => SpeakerAppBarState();
}

class SpeakerAppBarState extends State<SpeakerAppBar> {
  Duration? elapsedTime;
  Timer? sessionTimer;

  String hlsState = "HLS_STOPPED";
  Map<String, Participant> _participants = {};

  @override
  void initState() {
    startTimer();
    hlsState = widget.meeting.hlsState;

    _participants.putIfAbsent(widget.meeting.localParticipant.id,
        () => widget.meeting.localParticipant);
    _participants.addAll(widget.meeting.participants);

    addMeetingListener(widget.meeting);
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
                            fontWeight: FontWeight.w500,
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
              TouchRippleEffect(
                  rippleColor: primaryColor,
                  child: HLSIndicator(
                    hlsState: hlsState,
                    isButton: true,
                  ),
                  onTap: () {
                    if (hlsState == "HLS_STOPPING") {
                      showSnackBarMessage(
                          message: "HLS is in stopping state",
                          context: context);
                    } else if (hlsState == "HLS_STARTED" ||
                        hlsState == "HLS_PLAYABLE") {
                      widget.meeting.stopHls();
                    } else if (hlsState == "HLS_STARTING") {
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
              const HorizontalSpacer(),
              TouchRippleEffect(
                borderRadius: BorderRadius.circular(12),
                rippleColor: primaryColor,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: false,
                    builder: (context) =>
                        ParticipantList(meeting: widget.meeting),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: secondaryColor),
                    color: primaryColor,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        "assets/ic_participants.svg",
                        width: 22,
                        height: 22,
                        color: Colors.white,
                      ),
                      const HorizontalSpacer(4),
                      Text(_participants.length.toString()),
                    ],
                  ),
                ),
              ),
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

  void addMeetingListener(Room meeting) {
    meeting.on(Events.hlsStateChanged, (Map<String, dynamic> data) {
      if (mounted) {
        showSnackBarMessage(
            message:
                "Meeting HLS ${data['status'] == "HLS_STARTING" ? "is starting" : (data['status'] == "HLS_STARTED" || data['status'] == "HLS_PLAYABLE") ? "started" : data['status'] == "HLS_STOPPING" ? "is stopping" : "stopped"}",
            context: context);
      }
      setState(() {
        hlsState = data['status'];
      });
    });

    meeting.on(Events.participantJoined, (participant) {
      if (mounted) {
        final newParticipants = _participants;
        newParticipants[participant.id] = participant;
        setState(() => _participants = newParticipants);
      }
    });

    meeting.on(Events.participantLeft, (participantId) {
      if (mounted) {
        final newParticipants = _participants;
        newParticipants.remove(participantId);

        setState(() => _participants = newParticipants);
      }
    });
  }
}
