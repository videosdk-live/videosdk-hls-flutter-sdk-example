import 'package:flutter/material.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/app_bar/hls_indicator.dart';

class ViewerAppBar extends StatelessWidget {
  final String hlsState;
  final int participantCount;
  final Function onLeaveButtonPressed;
  const ViewerAppBar(
      {Key? key,
      required this.participantCount,
      required this.hlsState,
      required this.onLeaveButtonPressed})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6),
      child: Row(
        children: [
          IconButton(
              onPressed: () {
                onLeaveButtonPressed();
              },
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              )),
          if (hlsState == "HLS_STARTING" ||
              hlsState == "HLS_STOPPING" ||
              hlsState == "HLS_PLAYABLE" ||
              hlsState == "HLS_STARTED")
            HLSIndicator(
              hlsState: hlsState,
              isButton: false,
            ),
          if (hlsState == "HLS_STARTING" ||
              hlsState == "HLS_STOPPING" ||
              hlsState == "HLS_PLAYABLE" ||
              hlsState == "HLS_STARTED")
            const HorizontalSpacer(),
          if (hlsState == "HLS_STARTED")
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
                  Text(participantCount.toString()),
                ],
              ),
            )
        ],
      ),
    );
  }
}
