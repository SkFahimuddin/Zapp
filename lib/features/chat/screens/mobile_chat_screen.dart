import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../models/message.dart';
import '../../../core/enums/message_enum.dart';

class MobileChatScreen extends StatefulWidget {
  final String name;
  final String uid;
  final String profilePic;

  const MobileChatScreen({
    super.key,
    required this.name,
    required this.uid,
    required this.profilePic,
  });

  @override
  State<MobileChatScreen> createState() => _MobileChatScreenState();
}

class _MobileChatScreenState extends State<MobileChatScreen> {
  final messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isTyping = false;

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendNotification(String receiverId, String message) async {
    try {
      var receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      String? onesignalId = receiverDoc.data()?['onesignalId'];
      if (onesignalId == null) return;

      var senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      String senderName = senderDoc.data()?['name'] ?? 'Fi';

      await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'os_v2_app_habsmusibbaobo6ktrqp7f5f44tm5dkkkm5e7mupod37cnlconpbsnfoq4tzahowsbsvaqroq47hkjhir5zvwzbn3vmm2o6vqqz7kbq',
        },
        body: jsonEncode({
          'app_id': '38032652-4808-40e0-bbca-9c60ff97a5e7',
          'include_aliases': {
            'onesignal_id': [onesignalId]
          },
          'target_channel': 'push',
          'headings': {'en': senderName},
          'contents': {'en': message},
        }),
      );
    } catch (e) {
      // silently fail
    }
  }

  void sendMessage() async {
    String text = messageController.text.trim();
    if (text.isEmpty) return;

    String messageId = const Uuid().v1();
    DateTime now = DateTime.now();

    Message message = Message(
      senderId: currentUser.uid,
      receiverId: widget.uid,
      text: text,
      type: MessageEnum.text,
      timeSent: now,
      messageId: messageId,
      isSeen: false,
      repliedMessage: '',
      repliedTo: '',
      repliedMessageType: MessageEnum.text,
    );

    messageController.clear();
    setState(() => isTyping = false);

    // Get sender info from Firestore
    var myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    String senderName = myDoc.data()?['name'] ?? 'User';
    String senderPic = myDoc.data()?['profilePic'] ?? '';

    // Save to my chat
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('chats')
        .doc(widget.uid)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    // Save to receiver's chat
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('chats')
        .doc(currentUser.uid)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    // Update last message for me
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('chats')
        .doc(widget.uid)
        .set({
      'lastMessage': text,
      'timeSent': now.millisecondsSinceEpoch,
      'contactId': widget.uid,
      'name': widget.name,
      'profilePic': widget.profilePic,
    });

    // Update last message for receiver
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('chats')
        .doc(currentUser.uid)
        .set({
      'lastMessage': text,
      'timeSent': now.millisecondsSinceEpoch,
      'contactId': currentUser.uid,
      'name': senderName,
      'profilePic': senderPic,
    });

    await _sendNotification(widget.uid, text);
    scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0B141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2C34),
        elevation: 0,
        leadingWidth: 30,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF2A3942),
              backgroundImage: widget.profilePic.isNotEmpty
                  ? NetworkImage(widget.profilePic)
                  : null,
              child: widget.profilePic.isEmpty
                  ? Text(
                      widget.name.isNotEmpty
                          ? widget.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Color(0xFF00A884),
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const Text(
                  'tap for info',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('chats')
                  .doc(widget.uid)
                  .collection('messages')
                  .orderBy('timeSent')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00A884)));
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline,
                            color: Colors.white.withOpacity(0.2),
                            size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Messages are end-to-end encrypted',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => scrollToBottom());
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var msg = Message.fromMap(
                      snapshot.data!.docs[index].data()
                          as Map<String, dynamic>,
                    );
                    bool isMe = msg.senderId == currentUser.uid;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: _buildMessageInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    String timeStr =
        '${msg.timeSent.hour.toString().padLeft(2, '0')}:${msg.timeSent.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF005C4B)
              : const Color(0xFF1F2C34),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.text,
              style:
                  const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isSeen ? Icons.done_all : Icons.done,
                    size: 14,
                    color: msg.isSeen
                        ? const Color(0xFF00A884)
                        : Colors.white54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: const Color(0xFF1F2C34),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined,
                color: Colors.white54),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A3942),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                onChanged: (val) {
                  setState(() => isTyping = val.trim().isNotEmpty);
                },
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isTyping ? sendMessage : () {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00A884),
              ),
              child: Icon(
                isTyping ? Icons.send : Icons.mic,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}