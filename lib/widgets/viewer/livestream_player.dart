import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';
import 'package:touch_ripple_effect/touch_ripple_effect.dart';

class LivestreamPlayer extends StatefulWidget {
  final String downstreamUrl;
  final Orientation orientation;
  final bool showChat;
  final bool showOverlay;
  final Function onChatButtonClicked;
  final Function onRaiseHandButtonClicked;
  final Function onPlaybackEnded;
  const LivestreamPlayer({
    Key? key,
    required this.downstreamUrl,
    required this.orientation,
    required this.showChat,
    required this.showOverlay,
    required this.onChatButtonClicked,
    required this.onRaiseHandButtonClicked,
    required this.onPlaybackEnded,
  }) : super(key: key);

  @override
  LivestreamPlayerState createState() => LivestreamPlayerState();
}

class LivestreamPlayerState extends State<LivestreamPlayer>
    with AutomaticKeepAliveClientMixin {
  late VlcPlayerController _controller;

  //
  double sliderValue = 0.0;
  String position = '';
  String duration = '';
  bool validPosition = false;

  bool isHandRaised = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = VlcPlayerController.network(widget.downstreamUrl,
        options: VlcPlayerOptions());
    _controller.addListener(listener);
  }

  @override
  void dispose() async {
    _controller.removeListener(listener);
    _controller.dispose();
    super.dispose();
  }

  void listener() async {
    if (!mounted) return;
    //
    if (_controller.value.isInitialized) {
      var oPosition = _controller.value.position;
      var oDuration = _controller.value.duration;
      if (oPosition != null && oDuration != null) {
        if (oDuration.inHours == 0) {
          var strPosition = oPosition.toString().split('.')[0];
          var strDuration = oDuration.toString().split('.')[0];
          position =
              "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
          duration =
              "${strDuration.split(':')[1]}:${strDuration.split(':')[2]}";
        } else {
          position = oPosition.toString().split('.')[0];
          duration = oDuration.toString().split('.')[0];
        }
        validPosition = oDuration.compareTo(oPosition) >= 0;
        sliderValue = validPosition ? oPosition.inSeconds.toDouble() : 0;
      }
      if (_controller.value.isEnded) {
        widget.onPlaybackEnded();
      }
      setState(() {});
    }
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Flexible(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Center(
                child: VlcPlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                  placeholder: const Center(child: CircularProgressIndicator()),
                ),
              ),
              if (widget.orientation == Orientation.landscape &&
                  widget.showOverlay)
                Positioned(
                    top: 4,
                    right: 6,
                    child: Row(
                      children: [
                        TouchRippleEffect(
                          borderRadius: BorderRadius.circular(10),
                          rippleColor: primaryColor,
                          onTap: () {
                            if (!isHandRaised) {
                              widget.onRaiseHandButtonClicked();
                              setState(() {
                                isHandRaised = true;
                              });

                              Timer(const Duration(seconds: 5), () {
                                setState(() {
                                  isHandRaised = false;
                                });
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isHandRaised
                                  ? Color.fromRGBO(255, 255, 255, 1)
                                  : Color.fromRGBO(0, 0, 0, 0.3),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              "assets/ic_hand.svg",
                              color: isHandRaised ? Colors.black : Colors.white,
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                        const HorizontalSpacer(8),
                        TouchRippleEffect(
                          borderRadius: BorderRadius.circular(10),
                          rippleColor: primaryColor,
                          onTap: () {
                            widget.onChatButtonClicked();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: widget.showChat
                                  ? Color.fromRGBO(255, 255, 255, 1)
                                  : Color.fromRGBO(0, 0, 0, 0.3),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset("assets/ic_chat.svg",
                                color: widget.showChat
                                    ? Colors.black
                                    : Colors.white),
                          ),
                        ),
                      ],
                    )),
              if (widget.showOverlay)
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: _controller.value.isPlaying
                            ? Icon(Icons.pause)
                            : Icon(Icons.play_arrow),
                        onPressed: _togglePlaying,
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              position,
                              style: TextStyle(color: Colors.white),
                            ),
                            Expanded(
                              child: Slider(
                                activeColor: Colors.redAccent,
                                inactiveColor: Colors.white70,
                                value: sliderValue,
                                min: 0.0,
                                max: (!validPosition &&
                                        _controller.value.duration == null)
                                    ? 1.0
                                    : _controller.value.duration.inSeconds
                                        .toDouble(),
                                onChanged: validPosition
                                    ? _onSliderPositionChanged
                                    : null,
                              ),
                            ),
                            Text(
                              duration,
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: widget.orientation == Orientation.portrait
                            ? Icon(Icons.fullscreen)
                            : Icon(Icons.fullscreen_exit),
                        color: Colors.white,
                        onPressed: () {
                          if (widget.orientation == Orientation.portrait) {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]);
                          } else {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                            ]);
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _togglePlaying() async {
    _controller.value.isPlaying
        ? await _controller.pause()
        : await _controller.play();
  }

  void _onSliderPositionChanged(double progress) {
    setState(() {
      sliderValue = progress.floor().toDouble();
    });
    //convert to Milliseconds since VLC requires MS to set time
    _controller.setTime(sliderValue.toInt() * 1000);
  }
}
