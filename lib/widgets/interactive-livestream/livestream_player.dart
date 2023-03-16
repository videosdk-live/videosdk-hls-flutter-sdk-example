import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:lecle_yoyo_player/lecle_yoyo_player.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class LivestreamPlayer extends StatefulWidget {
  final String downstreamUrl;
  const LivestreamPlayer({super.key, required this.downstreamUrl});

  @override
  State<LivestreamPlayer> createState() => _LivestreamPlayerState();
}

class _LivestreamPlayerState extends State<LivestreamPlayer> {
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();

    // Initialize Chewie Controller
    // _chewieController = ChewieController(
    //     videoPlayerController: VideoPlayerController.network(
    //       widget.downstreamUrl,
    //     ),
    //     autoPlay: true,
    //     showControls: true,
    //     aspectRatio: 16 / 9,
    //     allowFullScreen: true,
    //     allowMuting: true,
    //     showOptions: true);
  }

  @override
  Widget build(BuildContext context) {
    // return Chewie(controller: _chewieController);
    return YoYoPlayer(
      aspectRatio: 16 / 9,
      url: widget.downstreamUrl,
      videoStyle:
          VideoStyle(bottomBarPadding: EdgeInsets.only(left: 16, right: 100)),
      videoLoadingStyle: VideoLoadingStyle(),
    );
  }
}
