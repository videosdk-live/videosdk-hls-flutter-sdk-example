import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/app_bar/hls_indicator.dart';

class LivestreamAppBar extends StatefulWidget {
  final Room meeting;
  final String hlsState;
  const LivestreamAppBar(
      {Key? key, required this.meeting, required this.hlsState})
      : super(key: key);

  @override
  State<LivestreamAppBar> createState() => LivestreamAppBarState();
}

class LivestreamAppBarState extends State<LivestreamAppBar> {
  int participants = 1;

  @override
  void initState() {
    super.initState();
    participants = widget.meeting.participants.length + 1;
    registerMeetingEventListener(widget.meeting);
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6),
      child: Row(
        children: [
          IconButton(
              onPressed: () {
                widget.meeting.leave();
              },
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              )),
          if (widget.hlsState == "HLS_STARTING" ||
              widget.hlsState == "HLS_STOPPING" ||
              widget.hlsState == "HLS_STARTED")
            HLSIndicator(hlsState: widget.hlsState),
          if (widget.hlsState == "HLS_STARTING" ||
              widget.hlsState == "HLS_STOPPING" ||
              widget.hlsState == "HLS_STARTED")
            const HorizontalSpacer(),
          if (widget.hlsState == "HLS_STARTED")
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color.fromRGBO(0, 0, 0, 0.3),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(
                    Icons.remove_red_eye,
                    size: 16,
                  ),
                  const HorizontalSpacer(6),
                  Text(participants.toString()),
                ],
              ),
            )
        ],
      ),
    );
  }

  void registerMeetingEventListener(Room meeting) {
    meeting.on(Events.participantJoined, (participant) {
      setState(() {
        participants = meeting.participants.length + 1;
      });
    });
    meeting.on(Events.participantLeft, (participant) {
      setState(() {
        participants = meeting.participants.length + 1;
      });
    });
  }
}
