import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/chat/screens/mobile_chat_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/login':
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case '/chat-list':
      return MaterialPageRoute(builder: (_) => const ChatListScreen());
    case '/chat':
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => MobileChatScreen(
          name: args['name'],
          uid: args['uid'],
          profilePic: args['profilePic'],
        ),
      );
    default:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
  }
}