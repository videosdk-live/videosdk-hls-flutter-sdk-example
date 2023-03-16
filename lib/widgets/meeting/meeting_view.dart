import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/utils/toast.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/participant/participant_list.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/meeting_controls/meeting_action_bar.dart';
import 'package:videosdk_hls_flutter_example/widgets/meeting/participant_grid.dart';
import 'package:videosdk_hls_flutter_example/widgets/meeting/screenshare_view.dart';

import 'package:videosdk_hls_flutter_example/widgets/common/app_bar/meeting_appbar.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/chat/chat_view.dart';

class MeetingView extends StatefulWidget {
  final Room meeting;
  const MeetingView({super.key, required this.meeting});

  @override
  State<MeetingView> createState() => _MeetingViewState();
}

class _MeetingViewState extends State<MeetingView> {
  bool showChatSnackbar = true;
  String recordingState = "RECORDING_STOPPED";
  String hlsState = "HLS_STOPPED";

  // Streams
  Stream? shareStream;
  Stream? videoStream;
  Stream? audioStream;
  Stream? remoteParticipantShareStream;

  @override
  void initState() {
    super.initState();
    // Register meeting events
    registerMeetingEvents(widget.meeting);
    subscribeToChatMessages(widget.meeting);
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;

    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Scaffold(
        backgroundColor: primaryColor,
        bottomNavigationBar: const TabBar(
          indicatorColor: primaryColor,
          tabs: [
            Tab(
              child: Text(
                "Chat",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Tab(
              child: Text(
                "Stage",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Tab(
              child: Text(
                "Participants",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            MeetingAppBar(
              meeting: widget.meeting,
              recordingState: recordingState,
              hlsState: hlsState,
            ),
            Expanded(
              child: TabBarView(children: [
                ChatView(meeting: widget.meeting),
                Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              ScreenShareView(meeting: widget.meeting),
                              Flexible(
                                  child:
                                      ParticipantGrid(meeting: widget.meeting))
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                ParticipantList(
                  meeting: widget.meeting,
                  showTitle: false,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void registerMeetingEvents(Room _meeting) {
    // Called when recording is started
    _meeting.on(Events.recordingStateChanged, (String status) {
      if (mounted) {
        showSnackBarMessage(
            message:
                "Meeting recording ${status == "RECORDING_STARTING" ? "is starting" : status == "RECORDING_STARTED" ? "started" : status == "RECORDING_STOPPING" ? "is stopping" : "stopped"}",
            context: context);
      }
      setState(() {
        recordingState = status;
      });
    });

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
    });

    // Called when stream is enabled
    _meeting.localParticipant.on(Events.streamEnabled, (Stream _stream) {
      if (_stream.kind == 'video') {
        setState(() {
          videoStream = _stream;
        });
      } else if (_stream.kind == 'audio') {
        setState(() {
          audioStream = _stream;
        });
      } else if (_stream.kind == 'share') {
        setState(() {
          shareStream = _stream;
        });
      }
    });

    // Called when stream is disabled
    _meeting.localParticipant.on(Events.streamDisabled, (Stream _stream) {
      if (_stream.kind == 'video' && videoStream?.id == _stream.id) {
        setState(() {
          videoStream = null;
        });
      } else if (_stream.kind == 'audio' && audioStream?.id == _stream.id) {
        setState(() {
          audioStream = null;
        });
      } else if (_stream.kind == 'share' && shareStream?.id == _stream.id) {
        setState(() {
          shareStream = null;
        });
      }
    });

    // Called when presenter is changed
    _meeting.on(Events.presenterChanged, (_activePresenterId) {
      Participant? activePresenterParticipant =
          _meeting.participants[_activePresenterId];

      // Get Share Stream
      Stream? _stream = activePresenterParticipant?.streams.values
          .singleWhere((e) => e.kind == "share");

      setState(() => remoteParticipantShareStream = _stream);
    });

    _meeting.on(
        Events.error,
        (error) => {
              if (mounted)
                {
                  showSnackBarMessage(
                      message: error['name'].toString() +
                          " :: " +
                          error['message'].toString(),
                      context: context)
                }
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

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
