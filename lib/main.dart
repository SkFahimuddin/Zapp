import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'core/constants/colors.dart';
import 'core/utils/notification_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'firebase_options.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // OneSignal
  OneSignal.initialize("38032652-4808-40e0-bbca-9c60ff97a5e7");
  OneSignal.Notifications.requestPermission(true);

  runApp(const ProviderScope(child: FiApp()));
}

class FiApp extends StatefulWidget {
  const FiApp({super.key});

  @override
  State<FiApp> createState() => _FiAppState();
}

class _FiAppState extends State<FiApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(backgroundColor: appBarColor),
      ),
      onGenerateRoute: (settings) => generateRoute(settings),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: tabColor),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            _notificationService.initialize(context);
            return const ChatListScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}