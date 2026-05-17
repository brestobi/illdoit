import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';
import 'supabase_service.dart';

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return NotificationService(supabaseService, ref);
});

/// Service for handling push notifications
class NotificationService {
  final SupabaseService _supabaseService;
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._supabaseService, this._ref);

  /// Initialize notifications
  Future<void> initialize() async {
    // 1. Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
    } else {
      log('User declined or has not accepted permission');
      return;
    }

    // 2. Setup local notifications for foreground messages
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 4. Handle background messages (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(jsonEncode(message.data));
    });
    
    // Check if app was opened from a terminated state via notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(jsonEncode(initialMessage.data));
    }

    // 5. Get and save the token
    await updateToken();
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    log('Notification payload: $payload');
    
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'chat') {
        final senderId = data['sender_id'];
        if (senderId != null) {
          _ref.read(goRouterProvider).push('/chat/$senderId');
        } else {
          _ref.read(goRouterProvider).push('/chat');
        }
      } else if (type == 'order') {
        _ref.read(goRouterProvider).push('/services');
      } else if (type == 'job_application') {
        final jobId = data['job_id'];
        if (jobId != null) {
          _ref.read(goRouterProvider).push('/job/$jobId');
        }
      } else if (type == 'payment') {
        _ref.read(goRouterProvider).push('/wallet');
      } else if (type == 'review') {
        final reviewerId = data['reviewer_id'];
        if (reviewerId != null) {
          _ref.read(goRouterProvider).push('/profile/$reviewerId');
        }
      } else {
        // Fallback for older notifications
        if (payload.contains('sender_id')) {
          final regExp = RegExp(r'sender_id: ([^,}\s]+)');
          final match = regExp.firstMatch(payload);
          if (match != null && match.group(1) != null) {
            _ref.read(goRouterProvider).push('/chat/${match.group(1)}');
          }
        }
      }
    } catch (e) {
      log('Error handling notification tap: $e');
    }
  }

  /// Update the FCM token in Supabase
  Future<void> updateToken() async {
    if (!_supabaseService.isAuthenticated) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        log('FCM Token: $token');
        await _supabaseService.update(
          table: 'users',
          id: _supabaseService.currentUser!.id,
          data: {'push_token': token},
        );
      }
    } catch (e) {
      log('Error updating FCM token: $e');
    }
  }

  /// Show a local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }
}
