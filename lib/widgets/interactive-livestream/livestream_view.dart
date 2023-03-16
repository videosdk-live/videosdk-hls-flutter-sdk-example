import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/utils/toast.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/app_bar/meeting_appbar.dart';
import 'package:videosdk_hls_flutter_example/widgets/interactive-livestream/livestream_appbar.dart';
import 'package:videosdk_hls_flutter_example/widgets/interactive-livestream/livestream_player.dart';
import 'package:videosdk_hls_flutter_example/widgets/interactive-livestream/waiting_for_hls.dart';

class LivestreamView extends StatefulWidget {
  final Room meeting;
  final String token;
  final String hlsState;
  final String? downstreamUrl;
  const LivestreamView(
      {super.key,
      required this.meeting,
      required this.token,
      required this.hlsState,
      required this.downstreamUrl});

  @override
  State<LivestreamView> createState() => _LivestreamViewState();
}

class _LivestreamViewState extends State<LivestreamView> {
  bool showChatSnackbar = true;

  @override
  void initState() {
    super.initState();
    // Register meeting events
    registerMeetingEvents(widget.meeting);
    subscribeToChatMessages(widget.meeting);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        LivestreamAppBar(meeting: widget.meeting, hlsState: widget.hlsState),
        if (widget.downstreamUrl == null ||
            widget.hlsState == "HLS_STARTING" ||
            widget.hlsState == "HLS_STOPPED")
          Expanded(
              child: WaitingForHLS(isStopped: widget.downstreamUrl != null)),
        if (widget.downstreamUrl != null &&
            (widget.hlsState == "HLS_STARTED" ||
                widget.hlsState == "HLS_STOPPING"))
          Expanded(
              child: LivestreamPlayer(
            downstreamUrl: widget.downstreamUrl!,
          )),
      ],
    );
  }

  void registerMeetingEvents(Room _meeting) {
    // Called when hls is started
    // _meeting.on(Events.hlsStateChanged, (Map<String, dynamic> data) {
    //   log("HLS STATE CHANGED");
    //   showSnackBarMessage(
    //       message:
    //           "Meeting HLS ${data['status'] == "HLS_STARTING" ? "is starting" : data['status'] == "HLS_STARTED" ? "started" : data['status'] == "HLS_STOPPING" ? "is stopping" : "stopped"}",
    //       context: context);

    //   setState(() {
    //     hlsState = data['status'];
    //   });
    //   if (data['status'] == "HLS_STARTED")
    //     Timer(Duration(seconds: 10), () {
    //       setState(() {
    //         hlsDownstreamUrl = data['downstreamUrl'];
    //       });
    //     });
    // });

    // _meeting.on(Events.hlsStarted, (String url) {
    //   // showSnackBarMessage(
    //   //     message:
    //   //         "Meeting HLS ${data['status'] == "HLS_STARTING" ? "is starting" : data['status'] == "HLS_STARTED" ? "started" : data['status'] == "HLS_STOPPING" ? "is stopping" : "stopped"}",
    //   //     context: context);

    //   setState(() {
    //     hlsState = "HLS_STARTED";
    //   });
    //   Timer(Duration(seconds: 5), () {
    //     setState(() {
    //       hlsDownstreamUrl = url;
    //     });
    //   });
    // });

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
