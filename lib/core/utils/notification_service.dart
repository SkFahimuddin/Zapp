import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await showLocalNotification(message);
}

Future<void> showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'fi_channel',
    'Fi Messages',
    channelDescription: 'Notifications for Fi messages',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'New Message',
    message.notification?.body ?? '',
    notificationDetails,
  );
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize(BuildContext context) async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);
      await flutterLocalNotificationsPlugin.initialize(initSettings);

      // Get FCM token and save to Firestore
      await _saveToken();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        showLocalNotification(message);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // navigate to chat when notification is tapped
      });
    }
  }

  Future<void> _saveToken() async {
    String? token = await _messaging.getToken();
    if (token != null && _auth.currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'fcmToken': token});
    }

    // Refresh token listener
    _messaging.onTokenRefresh.listen((newToken) async {
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'fcmToken': newToken});
      }
    });
  }
}