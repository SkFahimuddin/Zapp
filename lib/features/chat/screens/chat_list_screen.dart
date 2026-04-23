import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../contacts/screens/select_contacts_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text('Fi',
            style: TextStyle(color: tabColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('chats')
            .orderBy('timeSent', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No chats yet 💬',
                  style: TextStyle(color: greyColor)),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data()
                  as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(data['profilePic'] ?? ''),
                  backgroundColor: appBarColor,
                ),
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['lastMessage'] ?? '',
                    style: const TextStyle(color: greyColor)),
                onTap: () {
                  Navigator.pushNamed(context, '/chat', arguments: {
                    'name': data['name'],
                    'uid': data['contactId'],
                    'profilePic': data['profilePic'],
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: tabColor,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SelectContactsScreen()));
        },
        child: const Icon(Icons.chat, color: Colors.black),
      ),
    );
  }
}