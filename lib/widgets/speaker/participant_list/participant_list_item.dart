import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';

class ParticipantListItem extends StatefulWidget {
  final Participant participant;
  final Function onMoreOptionsSelected;
  final bool isRaisedHand;
  const ParticipantListItem(
      {Key? key,
      required this.participant,
      required this.isRaisedHand,
      required this.onMoreOptionsSelected})
      : super(key: key);

  @override
  State<ParticipantListItem> createState() => _ParticipantListItemState();
}

class _ParticipantListItemState extends State<ParticipantListItem> {
  Stream? videoStream;
  Stream? audioStream;

  @override
  void initState() {
    widget.participant.streams.forEach((key, Stream stream) {
      if (stream.kind == "video") {
        videoStream = stream;
      } else if (stream.kind == 'audio') {
        audioStream = stream;
      }
    });

    super.initState();
    addParticipantListener(widget.participant);
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          // padding: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: black500,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.person),
              ),
              Expanded(
                  child: Row(
                children: [
                  Text(
                    widget.participant.isLocal
                        ? "You"
                        : widget.participant.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.participant.mode == Mode.CONFERENCE)
                    Container(
                      decoration: BoxDecoration(
                        color: purple,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: const Text(
                        "Host",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              )),
              if (widget.isRaisedHand) SvgPicture.asset("assets/ic_hand.svg"),
              if (widget.isRaisedHand) const HorizontalSpacer(),
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: audioStream != null ? null : red,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(audioStream != null ? Icons.mic : Icons.mic_off),
              ),
              Container(
                // margin: EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: videoStream != null ? null : red,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SvgPicture.asset(videoStream != null
                    ? "assets/ic_video.svg"
                    : "assets/ic_video_off.svg"),
              ),
              if (!widget.participant.isLocal)
                PopupMenuButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: black700,
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                    onSelected: (value) {
                      widget.onMoreOptionsSelected(value);
                    },
                    itemBuilder: (context) {
                      return {
                        (widget.participant.mode == Mode.VIEWER
                            ? "Add as a Co-host"
                            : "Remove from Co-host"),
                        'Remove Participant'
                      }.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList();
                    }),
            ],
          ),
        ),
        const Divider(
          color: black600,
          thickness: 1.5,
        )
      ],
    );
  }

  void addParticipantListener(Participant participant) {
    participant.on(Events.streamEnabled, (Stream _stream) {
      if (mounted) {
        setState(() {
          if (_stream.kind == "video") {
            videoStream = _stream;
          } else if (_stream.kind == 'audio') {
            audioStream = _stream;
          }
        });
      }
    });

    participant.on(Events.streamDisabled, (Stream _stream) {
      if (mounted) {
        setState(() {
          if (_stream.kind == "video") {
            videoStream = null;
          } else if (_stream.kind == 'audio') {
            audioStream = null;
          }
        });
      }
    });
  }
}
