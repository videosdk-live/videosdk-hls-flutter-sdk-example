import 'package:flutter/material.dart';
import 'package:yoyo_player/yoyo_player.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:touch_ripple_effect/touch_ripple_effect.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';
// import 'package:chewie/chewie.dart';

class LivestreamPlayer extends StatefulWidget {
  final String downstreamUrl;
  final Orientation orientation;
  const LivestreamPlayer(
      {super.key, required this.downstreamUrl, required this.orientation});

  @override
  State<LivestreamPlayer> createState() => _LivestreamPlayerState();
}

class _LivestreamPlayerState extends State<LivestreamPlayer> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        YoYoPlayer(
          aspectRatio: 16 / 9,
          url: widget.downstreamUrl,
          videoStyle: VideoStyle(
            // videoQualityBgColor: Color.fromRGBO(0, 0, 0, 0.3),
            // qualityOptionsBgColor: Color.fromRGBO(0, 0, 0, 0.3),
            fullscreen: Icon(widget.orientation == Orientation.portrait
                ? Icons.fullscreen
                : Icons.fullscreen_exit),
            // bottomBarPadding: EdgeInsets.only(
            //     left: 16,
            //     right: widget.orientation == Orientation.portrait ? 16 : 100),
          ),
          videoLoadingStyle: VideoLoadingStyle(),
        ),
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
}
