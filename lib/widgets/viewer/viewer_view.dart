import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/utils/api.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';
import 'package:videosdk_hls_flutter_example/utils/toast.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/chat/chat_view.dart';
import 'package:videosdk_hls_flutter_example/widgets/viewer/viewer_appbar.dart';
import 'package:videosdk_hls_flutter_example/widgets/viewer/livestream_player.dart';
import 'package:videosdk_hls_flutter_example/widgets/viewer/waiting_for_hls.dart';

class ViewerView extends StatefulWidget {
  final Room meeting;
  const ViewerView({
    super.key,
    required this.meeting,
  });

  @override
  State<ViewerView> createState() => _ViewerViewState();
}

class _ViewerViewState extends State<ViewerView> {
  bool showChatSnackbar = true;

  late String hlsState;
  String? playbackHlsUrl;
  bool showChat = true;
  bool isEnded = false;
  bool showOverlay = true;
  int participants = 1;

  @override
  void initState() {
    super.initState();
    // Register meeting events
    hlsState = widget.meeting.hlsState;
    if (widget.meeting.hlsUrls != null) {
      playbackHlsUrl = widget.meeting.hlsUrls['playbackHlsUrl'];
    }
    participants = widget.meeting.participants.length + 1;

    registerMeetingEvents(widget.meeting);

    subscribeToChatMessages(widget.meeting);
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return Stack(
        children: [
          if (playbackHlsUrl == null ||
              hlsState == "HLS_STARTING" ||
              hlsState == "HLS_STOPPED" ||
              isEnded)
            WaitingForHLS(isStopped: isEnded),
          Flex(
            direction: orientation == Orientation.portrait
                ? Axis.vertical
                : Axis.horizontal,
            children: [
              if (orientation == Orientation.portrait) const VerticalSpacer(40),
              if (playbackHlsUrl != null &&
                  (hlsState == "HLS_PLAYABLE" || hlsState == "HLS_STOPPING") &&
                  !isEnded)
                Expanded(
                  flex: orientation == Orientation.landscape ? 2 : 1,
                  child: InkWell(
                    onTap: () {
                      if (!showOverlay) {
                        setState(() {
                          showOverlay = !showOverlay;
                        });
                        hideOverlay();
                      }
                    },
                    child: LivestreamPlayer(
                      playbackHlsUrl: playbackHlsUrl!,
                      orientation: orientation,
                      showChat: showChat,
                      showOverlay: showOverlay,
                      onChatButtonClicked: () {
                        setState(() {
                          showChat = !showChat;
                        });
                      },
                      onRaiseHandButtonClicked: () {
                        widget.meeting.pubSub.publish("RAISE_HAND", "message");
                      },
                      onPlaybackEnded: () {
                        setState(() {
                          isEnded = true;
                        });
                      },
                    ),
                  ),
                ),
              if (playbackHlsUrl != null &&
                  (hlsState == "HLS_PLAYABLE" || hlsState == "HLS_STOPPING") &&
                  (showChat || orientation == Orientation.portrait) &&
                  !isEnded)
                Expanded(
                    flex: orientation == Orientation.landscape ? 1 : 2,
                    child: ChatView(
                      meeting: widget.meeting,
                      showClose: orientation != Orientation.portrait,
                      orientation: orientation,
                      onClose: () {
                        setState(() {
                          showChat = !showChat;
                        });
                      },
                    ))
            ],
          ),
          if (showOverlay || orientation == Orientation.portrait)
            ViewerAppBar(
              participantCount: participants,
              hlsState: hlsState,
              onLeaveButtonPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: const Text("Are you sure you want to leave?"),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: black750,
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          MaterialButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: black600,
                              child: const Text("No",
                                  style: TextStyle(fontSize: 16)),
                              onPressed: () {
                                Navigator.pop(context);
                              }),
                          MaterialButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: purple,
                              child: const Text("Yes",
                                  style: TextStyle(fontSize: 16)),
                              onPressed: () {
                                widget.meeting.leave();
                              }),
                        ],
                      );
                    });
              },
            ),
        ],
      );
    });
  }

  void registerMeetingEvents(Room _meeting) {
    _meeting.on(Events.participantJoined, (participant) {
      setState(() {
        participants = _meeting.participants.length + 1;
      });
    });
    _meeting.on(Events.participantLeft, (participant) {
      setState(() {
        participants = _meeting.participants.length + 1;
      });
    });
    // Called when hls is started
    _meeting.on(Events.hlsStateChanged, (Map<String, dynamic> data) {
      setState(() {
        hlsState = data['status'];
      });
      if (data['status'] == "HLS_PLAYABLE") {
        setState(() {
          playbackHlsUrl = data['playbackHlsUrl'];
          isEnded = false;
          showOverlay = true;
          hideOverlay();
        });
      } else if (data['status'] == "HLS_STOPPED") {
        setState(() {
          playbackHlsUrl = null;
        });
      }
    });
    _meeting.on(
        Events.error,
        (error) => {
              showSnackBarMessage(
                  message: error['name'].toString() +
                      " :: " +
                      error['message'].toString(),
                  context: context)
            });
  }

  void subscribeToChatMessages(Room meeting) {
    meeting.pubSub.subscribe("CHAT", (message) {
      if (message.senderId != meeting.localParticipant.id) {
        if (mounted) {
          if (showChatSnackbar) {
            showSnackBarMessage(
                message: message.senderName + ": " + message.message,
                context: context);
          }
        }
      }
    });
  }

  Future<bool> isHlsPlayable(String url) async {
    int response = await fetchHls(url);
    if (response == 200) {
      return true;
    }
    return false;
  }

  void hideOverlay() {
    Timer(const Duration(seconds: 4), () {
      setState(() {
        showOverlay = false;
      });
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
