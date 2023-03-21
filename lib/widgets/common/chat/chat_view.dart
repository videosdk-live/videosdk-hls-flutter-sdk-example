import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:touch_ripple_effect/touch_ripple_effect.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';
import 'chat_widget.dart';

// ChatScreen
class ChatView extends StatefulWidget {
  final Room meeting;
  final bool showClose;
  final Orientation orientation;
  final Function onClose;
  const ChatView({
    Key? key,
    required this.meeting,
    required this.orientation,
    required this.onClose,
    required this.showClose,
  }) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  // MessageTextController
  final msgTextController = TextEditingController();

  // PubSubMessages
  PubSubMessages? messages;
  bool isRaisedHand = false;

  @override
  void initState() {
    super.initState();

    // Subscribing 'CHAT' Topic
    widget.meeting.pubSub
        .subscribe("CHAT", messageHandler)
        .then((value) => setState((() => messages = value)));
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: secondaryColor,
        appBar: AppBar(
          flexibleSpace: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      "Chat",
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                ),
                if (widget.showClose)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => widget.onClose(),
                  ),
              ],
            ),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: secondaryColor,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: messages == null
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          reverse: true,
                          child: Column(
                            children: messages!.messages
                                .map(
                                  (e) => ChatWidget(
                                    orientation: widget.orientation,
                                    message: e,
                                    isLocalParticipant: e.senderId ==
                                        widget.meeting.localParticipant.id,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: EdgeInsets.fromLTRB(
                            widget.orientation == Orientation.portrait
                                ? 16
                                : 10,
                            0,
                            0,
                            0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: black600),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                style: TextStyle(
                                  fontSize:
                                      widget.orientation == Orientation.portrait
                                          ? 16
                                          : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                controller: msgTextController,
                                onChanged: (value) => setState(() {
                                  msgTextController.text;
                                }),
                                decoration: const InputDecoration(
                                    hintText: "Write your message",
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: black400,
                                    )),
                              ),
                            ),
                            GestureDetector(
                              onTap: msgTextController.text.trim().isEmpty
                                  ? null
                                  : () => widget.meeting.pubSub
                                      .publish(
                                        "CHAT",
                                        msgTextController.text,
                                        const PubSubPublishOptions(
                                            persist: true),
                                      )
                                      .then(
                                          (value) => msgTextController.clear()),
                              child: Container(
                                  padding: const EdgeInsets.all(8),
                                  width: 45,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 0),
                                  decoration: BoxDecoration(
                                      color:
                                          msgTextController.text.trim().isEmpty
                                              ? null
                                              : purple,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.send)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!widget.showClose) const HorizontalSpacer(),
                    if (!widget.showClose)
                      TouchRippleEffect(
                        borderRadius: BorderRadius.circular(12),
                        rippleColor: primaryColor,
                        onTap: () {
                          if (!isRaisedHand) {
                            widget.meeting.pubSub
                                .publish("RAISE_HAND", "message");
                            setState(() {
                              isRaisedHand = true;
                            });

                            Timer(const Duration(seconds: 5), () {
                              setState(() {
                                isRaisedHand = false;
                              });
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isRaisedHand
                                ? Color.fromRGBO(255, 255, 255, 1)
                                : Color.fromRGBO(0, 0, 0, 0.3),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: SvgPicture.asset(
                            "assets/ic_hand.svg",
                            color: isRaisedHand ? Colors.black : Colors.white,
                            height: 24,
                            width: 24,
                          ),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void messageHandler(PubSubMessage message) {
    setState(() => messages!.messages.add(message));
  }

  @override
  void dispose() {
    widget.meeting.pubSub.unsubscribe("CHAT", messageHandler);
    super.dispose();
  }
}
