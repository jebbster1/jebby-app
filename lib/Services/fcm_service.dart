import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

import '../utils/api_headers.dart';
import '../res/app_url.dart';
import '../view_model/user_view_model.dart';
import '../Views/screens/reservations/reservation_detail_screen.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    await _initializeLocalNotifications();

    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _updateFCMToken(token);
    }

    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      _updateFCMToken(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message);
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = Map<String, dynamic>.from(json.decode(response.payload!) as Map);
            _openReservationFromData(data);
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jebby_notifications',
      'Jebby Notifications',
      channelDescription: 'Notifications from Jebby app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      message.notification?.title ?? 'Jebby',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }

  Future<void> _updateFCMToken(String token) async {
    try {
      final user = await UserViewModel().getUser();
      print('Updating FCM token for user: ${user.id}');
      
      final response = await http.post(
        Uri.parse(AppUrl.updateFCMToken),
        headers: await ApiHeaders.json(),
        body: json.encode({
          'user_id': user.id,
          'fcm_token': token,
        }),
      );

      if (response.statusCode == 200) {
        print('FCM token updated successfully');
      } else {
        print('Failed to update FCM token: ${response.body}');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _openReservationFromData(message.data);
  }

  void _openReservationFromData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final orderIdRaw = data['order_id'];
    final orderId = orderIdRaw is int ? orderIdRaw : int.tryParse('$orderIdRaw');

    const reservationTypes = {
      'booking_requested',
      'booking_request',
      'booking_accepted',
      'booking_declined',
      'booking_cancelled',
      'payment_confirmed',
      'address_revealed',
      'handoff_upcoming',
      'handoff_on_the_way',
      'handoff_arrived',
      'handoff_delayed',
      'inspection_started',
      'inspection_waiting',
      'inspection_completed',
      'dispute_reported',
      'issue_reported',
      'return_window_open',
      'payout_released',
      'new_order',
      'payment_success',
    };

    if (orderId != null && (reservationTypes.contains(type) || type != null)) {
      Get.to(() => ReservationDetailScreen(orderId: orderId));
      return;
    }

    switch (type) {
      case 'payment_success':
      case 'payment_processed':
        print('Navigate to transactions screen');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
}
