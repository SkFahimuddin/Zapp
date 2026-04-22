import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import '../controller/auth_controller.dart';

class UserInfoScreen extends ConsumerStatefulWidget {
  final String email;
  final String password;
  const UserInfoScreen({super.key, required this.email, required this.password});

  @override
  ConsumerState<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends ConsumerState<UserInfoScreen> {
  final nameController = TextEditingController();
  File? image;

  void pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  void saveUserData() {
    String name = nameController.text.trim();
    if (name.isEmpty) return;
    ref.read(authControllerProvider).signUpWithEmail(
        context, widget.email, widget.password, name, image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: appBarColor,
                backgroundImage: image != null ? FileImage(image!) : null,
                child: image == null
                    ? const Icon(Icons.person, size: 60, color: greyColor)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Tap to add profile photo',
                style: TextStyle(color: greyColor)),
            const SizedBox(height: 30),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Your name',
                prefixIcon: Icon(Icons.person, color: tabColor),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: tabColor)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: tabColor)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tabColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: saveUserData,
                child: const Text('CONTINUE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}