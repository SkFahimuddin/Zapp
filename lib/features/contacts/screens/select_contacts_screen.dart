import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class SelectContactsScreen extends StatefulWidget {
  const SelectContactsScreen({super.key});

  @override
  State<SelectContactsScreen> createState() => _SelectContactsScreenState();
}

class _SelectContactsScreenState extends State<SelectContactsScreen> {
  final searchController = TextEditingController();
  String searchQuery = '';
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void selectContact(BuildContext context, UserModel user) {
    Navigator.pushNamed(context, '/chat', arguments: {
      'name': user.name,
      'uid': user.uid,
      'profilePic': user.profilePic,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Chat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                autofocus: true,
                onChanged: (val) {
                  setState(() => searchQuery = val.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF00A884), size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.white38, size: 18),
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Users list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00A884)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4)),
                    ),
                  );
                }

                // Filter users
                var users = snapshot.data!.docs
                    .map((doc) => UserModel.fromMap(
                        doc.data() as Map<String, dynamic>))
                    .where((user) => user.uid != currentUser.uid)
                    .where((user) {
                  if (searchQuery.isEmpty) return false;
                  return user.name.toLowerCase().contains(searchQuery);
                }).toList();

                if (users.isEmpty && searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            color: Colors.white.withOpacity(0.2),
                            size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No results for "$searchQuery"',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4)),
                        ),
                      ],
                    ),
                  );
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            color: Colors.white.withOpacity(0.2),
                            size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No other users yet',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserTile(context, user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, UserModel user) {
    return GestureDetector(
      onTap: () => selectContact(context, user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF1A1A1A),
              backgroundImage: user.profilePic.isNotEmpty
                  ? NetworkImage(user.profilePic)
                  : null,
              child: user.profilePic.isEmpty
                  ? Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Color(0xFF00A884),
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.phoneNumber.isEmpty
                        ? 'Fi user'
                        : user.phoneNumber,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chat_bubble_outline,
                color: const Color(0xFF00A884).withOpacity(0.6), size: 20),
          ],
        ),
      ),
    );
  }
}