import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/auth_repository.dart';
import '../../../models/user_model.dart';

final authControllerProvider = Provider((ref) => AuthController(
      authRepository: ref.read(authRepositoryProvider),
      ref: ref,
    ));

final userDataAuthProvider = FutureProvider((ref) {
  final authController = ref.watch(authControllerProvider);
  return authController.getUserData();
});

class AuthController {
  final AuthRepository authRepository;
  final ProviderRef ref;

  AuthController({required this.authRepository, required this.ref});

  Future<UserModel?> getUserData() async {
    return authRepository.getCurrentUserData();
  }

  void signUpWithEmail(BuildContext context, String email, String password,
      String name, File? profilePic) {
    authRepository.signUpWithEmail(context, email, password, name, profilePic);
  }

  void signInWithEmail(BuildContext context, String email, String password) {
    authRepository.signInWithEmail(context, email, password);
  }

  void forgotPassword(BuildContext context, String email) {
    authRepository.forgotPassword(context, email);
  }

  void signOut() {
    authRepository.signOut();
  }
}