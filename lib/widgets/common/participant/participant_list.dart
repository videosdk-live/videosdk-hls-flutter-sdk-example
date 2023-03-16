import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/participant/participant_list_item.dart';

class ParticipantList extends StatefulWidget {
  final Room meeting;
  final bool showTitle;
  const ParticipantList(
      {Key? key, required this.meeting, required this.showTitle})
      : super(key: key);

  @override
  State<ParticipantList> createState() => _ParticipantListState();
}

class _ParticipantListState extends State<ParticipantList> {
  Map<String, Participant> _participants = {};

  @override
  void initState() {
    _participants.putIfAbsent(widget.meeting.localParticipant.id,
        () => widget.meeting.localParticipant);
    _participants.addAll(widget.meeting.participants);
    addMeetingListeners(widget.meeting);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: widget.showTitle
          ? AppBar(
              backgroundColor: primaryColor,
              flexibleSpace: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          "Participants (" +
                              (widget.meeting.participants.length + 1)
                                  .toString() +
                              ")",
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              automaticallyImplyLeading: false,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _participants.values.length,
                itemBuilder: (context, index) => ParticipantListItem(
                  participant: _participants.values.elementAt(index),
                  onMoreOptionsSelected: (value) {
                    if (value == "Remove from Co-host" ||
                        value == "Add as a Co-host") {
                      log("Selected Change Mode ${_participants.values.elementAt(index).id}");
                      widget.meeting.pubSub.publish(
                          "CHANGE_MODE_${_participants.values.elementAt(index).id}",
                          jsonEncode({
                            "mode":
                                _participants.values.elementAt(index).mode ==
                                        Mode.CONFERENCE
                                    ? Mode.VIEWER.name
                                    : Mode.CONFERENCE.name
                          }));
                    } else if (value == "Remove Participant") {
                      log("Selected remove participnt");

                      _participants.values.elementAt(index).remove();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void addMeetingListeners(Room meeting) {
    meeting.on(Events.participantJoined, (participant) {
      if (mounted) {
        final newParticipants = _participants;
        newParticipants[participant.id] = participant;
        setState(() => _participants = newParticipants);
      }
    });

    meeting.on(Events.participantModeChanged, (data) {
      if (mounted) {
        final newParticipants = _participants;
        newParticipants[data['participantId']]?.mode =
            meeting.participants[data['participantId']]!.mode;
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
