import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/utils/api.dart';
import 'package:videosdk_hls_flutter_example/utils/toast.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/chat/chat_view.dart';
import 'package:videosdk_hls_flutter_example/widgets/interactive-livestream/livestream_appbar.dart';
import 'package:videosdk_hls_flutter_example/widgets/interactive-livestream/livestream_player.dart';
import 'package:videosdk_hls_flutter_example/widgets/interactive-livestream/waiting_for_hls.dart';

class LivestreamView extends StatefulWidget {
  final Room meeting;
  const LivestreamView({
    super.key,
    required this.meeting,
  });

  @override
  State<LivestreamView> createState() => _LivestreamViewState();
}

class _LivestreamViewState extends State<LivestreamView> {
  bool showChatSnackbar = true;

  late String hlsState;
  String? downstreamUrl;
  bool showChat = true;
  bool isEnded = false;

  @override
  void initState() {
    super.initState();
    // Register meeting events
    hlsState = widget.meeting.hlsState;
    if (widget.meeting.hlsDownstreamUrl != null) {
      updateDownstreamUrl(widget.meeting.hlsDownstreamUrl!);
    }

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
    return Stack(
      // mainAxisSize: MainAxisSize.max,
      children: [
        if (downstreamUrl == null ||
            hlsState == "HLS_STARTING" ||
            hlsState == "HLS_STOPPED" ||
            isEnded)
          WaitingForHLS(isStopped: isEnded),
        OrientationBuilder(builder: (context, orientation) {
          return Flex(
            direction: orientation == Orientation.portrait
                ? Axis.vertical
                : Axis.horizontal,
            children: [
              if (downstreamUrl != null &&
                  (hlsState == "HLS_STARTED" || hlsState == "HLS_STOPPING") &&
                  !isEnded)
                Expanded(
                  flex: orientation == Orientation.landscape ? 2 : 1,
                  child: LivestreamPlayer(
                    downstreamUrl: downstreamUrl!,
                    orientation: orientation,
                    showChat: showChat,
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
              if (downstreamUrl != null &&
                  (hlsState == "HLS_STARTED" || hlsState == "HLS_STOPPING") &&
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
          );
        }),
        LivestreamAppBar(meeting: widget.meeting, hlsState: hlsState),
      ],
    );
  }

  void registerMeetingEvents(Room _meeting) {
    // Called when hls is started

    _meeting.on(Events.hlsStateChanged, (Map<String, dynamic> data) {
      setState(() {
        hlsState = data['status'];
      });
      if (data['status'] == "HLS_STARTED") {
        Timer(const Duration(seconds: 10),
            () => {updateDownstreamUrl(data['downstreamUrl'])});
      } else if (data['status'] == "HLS_STOPPED") {
        setState(() {
          downstreamUrl = null;
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
    log("URL response ${response}");
    if (response == 200) {
      return true;
    }
    return false;
  }

  void updateDownstreamUrl(String url) {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      bool isPlayable = await isHlsPlayable(url);
      setState(() {
        downstreamUrl = url;
        isEnded = false;
      });
      timer.cancel();
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
