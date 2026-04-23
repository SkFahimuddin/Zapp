import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../models/user_model.dart';

class SelectContactsScreen extends ConsumerWidget {
  const SelectContactsScreen({super.key});

  void selectContact(BuildContext context, UserModel user) {
    Navigator.pushNamed(context, '/chat', arguments: {
      'name': user.name,
      'uid': user.uid,
      'profilePic': user.profilePic,
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contact'),
        backgroundColor: appBarColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: tabColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No users found', style: TextStyle(color: greyColor)),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var user = UserModel.fromMap(
                snapshot.data!.docs[index].data() as Map<String, dynamic>,
              );
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user.profilePic),
                  backgroundColor: appBarColor,
                ),
                title: Text(user.name),
                subtitle: Text(user.phoneNumber.isEmpty ? user.uid.substring(0, 8) : user.phoneNumber),
                onTap: () => selectContact(context, user),
              );
            },
          );
        },
      ),
    );
  }
}