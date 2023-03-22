import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/screens/speaker_join_screen.dart';
import 'package:videosdk_hls_flutter_example/screens/viewer_join_screen.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: purple,
                child: const Text("Create a meeting",
                    style: TextStyle(fontSize: 16)),
                onPressed: () => {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SpeakerJoinScreen(
                                  isCreateMeeting: true)))
                    }),
            const VerticalSpacer(32),
            Row(
              children: const [
                Expanded(
                    child: Divider(
                  thickness: 1,
                  color: black750,
                )),
                HorizontalSpacer(),
                Text("OR"),
                HorizontalSpacer(),
                Expanded(
                    child: Divider(
                  thickness: 1,
                  color: black750,
                )),
              ],
            ),
            const VerticalSpacer(32),
            MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: black750,
                child: const Text("Join as a speaker",
                    style: TextStyle(fontSize: 16)),
                onPressed: () => {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SpeakerJoinScreen(
                                  isCreateMeeting: false)))
                    }),
            const VerticalSpacer(12),
            MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: black750,
                child: const Text("Join as a viewer",
                    style: TextStyle(fontSize: 16)),
                onPressed: () => {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ViewerJoinScreen()))
                    }),
          ],
        ),
      )),
    );
  }
}
