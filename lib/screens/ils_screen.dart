import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/screens/home_screen.dart';
import 'package:videosdk_hls_flutter_example/utils/toast.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/joining/waiting_to_join.dart';
import 'package:videosdk_hls_flutter_example/widgets/viewer/viewer_view.dart';
import 'package:videosdk_hls_flutter_example/widgets/speaker/speaker_view.dart';

class ILSScreen extends StatefulWidget {
  final String meetingId, token, displayName;
  final bool micEnabled, camEnabled, chatEnabled;
  final Mode mode;
  const ILSScreen({
    Key? key,
    required this.meetingId,
    required this.token,
    required this.displayName,
    required this.mode,
    this.micEnabled = true,
    this.camEnabled = true,
    this.chatEnabled = true,
  }) : super(key: key);

  @override
  State<ILSScreen> createState() => _ILSScreenState();
}

class _ILSScreenState extends State<ILSScreen> {
  // Meeting
  late Room meeting;
  bool _joined = false;

  Mode? localParticipantMode;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    // Create instance of Room (Meeting)
    Room room = VideoSDK.createRoom(
      roomId: widget.meetingId,
      token: widget.token,
      displayName: widget.displayName,
      micEnabled: widget.micEnabled,
      camEnabled: widget.camEnabled,
      maxResolution: 'hd',
      multiStream: true,
      defaultCameraIndex: 1,
      mode: widget.mode,
      notification: const NotificationInfo(
        title: "Video SDK",
        message: "Video SDK is sharing screen in the meeting",
        icon: "notification_share", // drawable icon name
      ),
    );

    localParticipantMode = widget.mode;

    // Register meeting events
    registerMeetingEvents(room);

    // Join meeting
    room.join();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPopScope,
      child: _joined
          ? SafeArea(
              child: Scaffold(
                  backgroundColor: Theme.of(context).primaryColor,
                  body: localParticipantMode == Mode.CONFERENCE
                      ? SpeakerView(meeting: meeting, token: widget.token)
                      : ViewerView(
                          meeting: meeting,
                        )))
          : const WaitingToJoin(),
    );
  }

  void registerMeetingEvents(Room _meeting) {
    // Called when joined in meeting
    _meeting.on(
      Events.roomJoined,
      () {
        if (widget.mode == Mode.CONFERENCE) {
          _meeting.localParticipant.pin();
        }
        setState(() {
          meeting = _meeting;
          localParticipantMode = _meeting.localParticipant.mode;
          _joined = true;
        });
        registerModeListener(_meeting);
      },
    );

    _meeting.on(Events.participantModeChanged, (Map<String, dynamic> data) {
      if (data['participantId'] == _meeting.localParticipant.id) {
        if (_meeting.localParticipant.mode == Mode.CONFERENCE) {
          meeting.localParticipant.pin();
        } else {
          meeting.localParticipant.unpin();
        }
        setState(() {
          localParticipantMode = _meeting.localParticipant.mode;
        });
      }
    });

    // Called when meeting is ended
    _meeting.on(Events.roomLeft, (String? errorMsg) {
      if (errorMsg != null) {
        showSnackBarMessage(
            message: "Meeting left due to $errorMsg !!", context: context);
      }
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false);
    });

    _meeting.on(
        Events.error,
        (error) => {
              showSnackBarMessage(
                  message: "${error['name']} :: ${error['message']}",
                  context: context)
            });
  }

  void registerModeListener(Room _meeting) async {
    PubSubMessages messages = await _meeting.pubSub
        .subscribe("CHANGE_MODE_${_meeting.localParticipant.id}",
            (PubSubMessage pubSubMessage) {
      Map<dynamic, dynamic> message = jsonDecode(pubSubMessage.message);
      if (mounted) {
        if (message['mode'] == Mode.CONFERENCE.name) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Text(
                      "${pubSubMessage.senderName} requested to join as a speaker"),
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
                        child: const Text("Decline",
                            style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                    MaterialButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: purple,
                        child: const Text("Accept",
                            style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          _meeting.changeMode(Mode.CONFERENCE);
                          Navigator.pop(context);
                        }),
                  ],
                );
              });
        } else {
          _meeting.changeMode(Mode.VIEWER);
        }
      }
    });
  }

  Future<bool> _onWillPopScope() async {
    meeting.leave();
    return true;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
