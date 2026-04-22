import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
      firestore: ref.read(firestoreProvider),
      auth: ref.read(authProvider),
      storage: ref.read(storageProvider),
    ));

class AuthRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FirebaseStorage storage;

  AuthRepository({
    required this.firestore,
    required this.auth,
    required this.storage,
  });

  Future<UserModel?> getCurrentUserData() async {
    var userData =
        await firestore.collection('users').doc(auth.currentUser?.uid).get();
    if (userData.data() != null) return UserModel.fromMap(userData.data()!);
    return null;
  }

  void signUpWithEmail(BuildContext context, String email, String password,
      String name, File? profilePic) async {
    try {
      UserCredential cred = await auth.createUserWithEmailAndPassword(
          email: email, password: password);

      String uid = cred.user!.uid;
      String photoUrl =
          'https://png.pngitem.com/pimgs/s/649-6490124_katie-notopoulos-katienotopoulos-i-write-about-tech-round.png';

      if (profilePic != null) {
        photoUrl = await _storeFileToFirebase('profilePic/$uid', profilePic);
      }

      var user = UserModel(
        name: name,
        uid: uid,
        profilePic: photoUrl,
        isOnline: true,
        phoneNumber: '',
        groupId: [],
      );

      await firestore.collection('users').doc(uid).set(user.toMap());
      Navigator.pushNamedAndRemoveUntil(
          context, '/chat-list', (route) => false);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
    }
  }

  void signInWithEmail(
      BuildContext context, String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushNamedAndRemoveUntil(
          context, '/chat-list', (route) => false);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
    }
  }

  void forgotPassword(BuildContext context, String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
    }
  }

  void signOut() async {
    await auth.signOut();
  }

  Future<String> _storeFileToFirebase(String ref, File file) async {
    UploadTask uploadTask = storage.ref().child(ref).putFile(file);
    TaskSnapshot snap = await uploadTask;
    return await snap.ref.getDownloadURL();
  }
}