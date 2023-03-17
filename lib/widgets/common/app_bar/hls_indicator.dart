import 'package:flutter/widgets.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';

class HLSIndicator extends StatefulWidget {
  final String hlsState;
  const HLSIndicator({Key? key, required this.hlsState}) : super(key: key);

  @override
  State<HLSIndicator> createState() => _HLSIndicatorState();
}

class _HLSIndicatorState extends State<HLSIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    if (widget.hlsState == "HLS_STARTING" ||
        widget.hlsState == "HLS_STOPPING") {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.forward();
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant HLSIndicator oldWidget) {
    if (widget.hlsState == "HLS_STARTED" || widget.hlsState == "HLS_STOPPED") {
      _animationController.stop();
      _animationController.forward();
    } else {
      _animationController.repeat(reverse: true);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: _animationController,
        // child: Lottie.asset('assets/recording_lottie.json', height: 35));
        child: Container(
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4)), color: red),
            padding: const EdgeInsets.all(8),
            child: const Text("Live")));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
