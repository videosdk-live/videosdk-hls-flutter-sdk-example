import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/utils/api.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';
import 'package:videosdk_hls_flutter_example/utils/toast.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/app_bar/hls_indicator.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/app_bar/recording_indicator.dart';

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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
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
        ],
      ),
    );
  }
}
