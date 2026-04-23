import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final currentUser = FirebaseAuth.instance.currentUser!;

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

    // Update last message for both
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

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('chats')
        .doc(currentUser.uid)
        .set({
      'lastMessage': text,
      'timeSent': now.millisecondsSinceEpoch,
      'contactId': currentUser.uid,
      'name': currentUser.displayName ?? 'User',
      'profilePic': currentUser.photoURL ?? '',
    });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.profilePic),
              backgroundColor: greyColor,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Text(widget.name, style: const TextStyle(fontSize: 16)),
          ],
        ),
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
                  return const Center(child: CircularProgressIndicator(color: tabColor));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var msg = Message.fromMap(
                      snapshot.data!.docs[index].data() as Map<String, dynamic>,
                    );
                    bool isMe = msg.senderId == currentUser.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? messageColor : senderMessageColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg.text, style: const TextStyle(color: textColor)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: chatBarMessage,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: tabColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 20),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}