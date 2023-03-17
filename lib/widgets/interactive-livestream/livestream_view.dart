import 'dart:async';

import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/utils/toast.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/chat/chat_view.dart';
import 'package:videosdk_hls_flutter_example/widgets/interactive-livestream/livestream_appbar.dart';
import 'package:videosdk_hls_flutter_example/widgets/interactive-livestream/livestream_player.dart';
import 'package:videosdk_hls_flutter_example/widgets/interactive-livestream/livestream_player_simple.dart';
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

  @override
  void initState() {
    super.initState();
    // Register meeting events
    hlsState = widget.meeting.hlsState;
    downstreamUrl = widget.meeting.hlsDownstreamUrl;

    registerMeetingEvents(widget.meeting);

    subscribeToChatMessages(widget.meeting);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        LivestreamAppBar(meeting: widget.meeting, hlsState: hlsState),
        if (downstreamUrl == null ||
            hlsState == "HLS_STARTING" ||
            hlsState == "HLS_STOPPED")
          Expanded(child: WaitingForHLS(isStopped: downstreamUrl != null)),
        Expanded(
          child: OrientationBuilder(builder: (context, orientation) {
            return Flex(
              direction: orientation == Orientation.portrait
                  ? Axis.vertical
                  : Axis.horizontal,
              children: [
                if (downstreamUrl != null &&
                    (hlsState == "HLS_STARTED" || hlsState == "HLS_STOPPING"))
                  // Expanded(
                  //   flex: orientation == Orientation.landscape ? 2 : 1,
                  //   child: LivestreamPlayerSimple(
                  //     downstreamUrl: downstreamUrl!,
                  //     orientation: orientation,
                  //     meeting: widget.meeting,
                  //   ),
                  // ),
                  Expanded(
                    flex: orientation == Orientation.landscape ? 2 : 1,
                    child: LivestreamPlayer(
                      downstreamUrl: downstreamUrl!,
                      orientation: orientation,
                      // meeting: widget.meeting,
                    ),
                  ),
                Expanded(
                    flex: orientation == Orientation.landscape ? 1 : 2,
                    child: ChatView(meeting: widget.meeting, showClose: false))
              ],
            );
          }),
        )
      ],
    );
  }

  void registerMeetingEvents(Room _meeting) {
    // Called when hls is started

    _meeting.on(Events.hlsStateChanged, (Map<String, dynamic> data) {
      if (mounted) {
        showSnackBarMessage(
            message:
                "Meeting HLS ${data['status'] == "HLS_STARTING" ? "is starting" : data['status'] == "HLS_STARTED" ? "started" : data['status'] == "HLS_STOPPING" ? "is stopping" : "stopped"}",
            context: context);
      }
      setState(() {
        hlsState = data['status'];
      });
      if (data['status'] == "HLS_STARTED") {
        Timer(const Duration(seconds: 10), () {
          setState(() {
            downstreamUrl = data['downstreamUrl'];
          });
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
}
