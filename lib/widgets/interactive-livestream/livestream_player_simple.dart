import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/utils/api.dart';
import 'package:yoyo_player/yoyo_player.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:touch_ripple_effect/touch_ripple_effect.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';
// import 'package:chewie/chewie.dart';

class LivestreamPlayerSimple extends StatefulWidget {
  final String downstreamUrl;
  final Orientation orientation;
  final Room meeting;
  const LivestreamPlayerSimple(
      {super.key,
      required this.meeting,
      required this.downstreamUrl,
      required this.orientation});

  @override
  State<LivestreamPlayerSimple> createState() => _LivestreamPlayerSimpleState();
}

class _LivestreamPlayerSimpleState extends State<LivestreamPlayerSimple> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.downstreamUrl);

    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    // Initialize the controller and store the Future for later use.
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.play();
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // If the VideoPlayerController has finished initialization, use
              // the data it provides to limit the aspect ratio of the video.
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                // Use the VideoPlayer widget to display the video.
                child: VideoPlayer(_controller),
              );
            } else {
              // If the VideoPlayerController is still initializing, show a
              // loading spinner.
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
        _ControlsOverlay(controller: _controller, meeting: widget.meeting),
        if (widget.orientation == Orientation.landscape)
          Positioned(
              bottom: 10,
              right: 0,
              child: Row(
                children: [
                  TouchRippleEffect(
                    borderRadius: BorderRadius.circular(12),
                    rippleColor: primaryColor,
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Color.fromRGBO(0, 0, 0, 0.3),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        "assets/ic_hand.svg",
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const HorizontalSpacer(8),
                  TouchRippleEffect(
                    borderRadius: BorderRadius.circular(12),
                    rippleColor: primaryColor,
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Color.fromRGBO(0, 0, 0, 0.3),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        "assets/ic_chat.svg",
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )),
      ],
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }
}

class _ControlsOverlay extends StatefulWidget {
  const _ControlsOverlay({required this.controller, required this.meeting});
  final Room meeting;
  final VideoPlayerController controller;

  @override
  State<_ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  bool showOverlay = true;

  Duration? elapsedTime;
  Timer? hlsTimer;

  @override
  void initState() {
    super.initState();
    startTimer();
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
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: !showOverlay
              ? const SizedBox.shrink()
              : Column(children: [
                  Expanded(
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        color: Colors.white,
                        onPressed: () {
                          if (widget.controller.value.isPlaying) {
                            widget.controller.pause();
                          } else {
                            widget.controller.play();
                          }
                        },
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(widget.controller.value.position.inSeconds
                          .toString()),
                      Flex(
                        direction: Axis.horizontal,
                      ),
                      Text(elapsedTime?.inSeconds.toString() ?? ""),
                    ],
                  ),
                  if (elapsedTime != null)
                    Slider(
                        min: 0,
                        max: elapsedTime?.inSeconds.toDouble() ?? 1,
                        value: widget.controller.value.position.inSeconds
                            .toDouble(),
                        onChanged: (double newValue) {
                          widget.controller
                              .seekTo(Duration(seconds: newValue.toInt()));
                        }),
                ]),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              showOverlay = !showOverlay;
            });
          },
        ),
      ],
    );
  }

  Future<void> startTimer() async {
    String token = await fetchToken(context);
    dynamic hls = await fetchActiveHls(token, widget.meeting.id);
    DateTime hlsStartTime = DateTime.parse(hls['start']);
    final difference = DateTime.now().difference(hlsStartTime);

    setState(() {
      elapsedTime = difference;
      hlsTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          setState(() {
            elapsedTime = Duration(
                seconds: elapsedTime != null ? elapsedTime!.inSeconds + 1 : 0);
          });
        },
      );
    });
    // log("session start time" + session.data[0].start.toString());
  }

  @override
  void dispose() {
    hlsTimer?.cancel();
    super.dispose();
  }
}
