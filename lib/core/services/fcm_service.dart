import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'order_channel_id',
    'Order Notifications',
    description: 'This channel is used for important order notifications.',
    importance: Importance.max,
    playSound: true,
  );

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Note: Use print here carefully as it might not show up in all debug consoles for background processes
    debugPrint("Handling a background message: ${message.messageId}");
  }

  static Future<void> initialize() async {
    print('FCMService: Initializing...');
    
    // 1. Request permissions
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false, // Set to true for silent notifications on iOS
      );

      print('FCMService: Permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('FCMService: User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('FCMService: User granted provisional permission');
      } else {
        print('FCMService: User declined or has not accepted notification permission');
      }
    } catch (e) {
      print('FCMService: Error requesting permission: $e');
    }

    // 2. Initialize Flutter Local Notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(initSettings);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Configure FCM options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Initial Token Sync
    await syncToken();

    // 5. Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      print('FCMService: Token refreshed: ${newToken.substring(0, 5)}...');
      _saveTokenToSupabase(newToken);
    });

    // 6. Auth state listener for token sync
    // This ensures that when a user logs in, their token is immediately saved even if initialization happened while logged out.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      print('FCMService: Auth state change detected: $event');
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        syncToken();
      }
    });

    // 7. Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 8. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('FCMService: Received foreground message: ${message.notification?.title}');
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: android.smallIcon,
            ),
          ),
        );
      }
    });
    
    print('FCMService: Initialization complete');
  }

  static Future<void> syncToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print('FCMService: Fetched FCM Token: ${token.substring(0, 10)}...');
        await _saveTokenToSupabase(token);
      } else {
        print('FCMService: Failed to get FCM token (null)');
      }
    } catch (e) {
      print('FCMService: Error in syncToken: $e');
    }
  }

  static Future<void> sendWelcomeNotification(String type) async {
    final user = Supabase.instance.client.auth.currentUser;
    print('FCMService: Attempting to trigger $type notification for: ${user?.id}');
    
    if (user == null) {
      print('FCMService: Cannot send notification - No user logged in');
      return;
    }

    try {
      String? token = await _messaging.getToken();
      if (token == null) {
        print('FCMService: Cannot send notification - Token is null');
        return;
      }

      print('FCMService: Invoking Edge Function "welcome-notification"...');
      final response = await Supabase.instance.client.functions.invoke(
        'welcome-notification',
        body: {
          'fcm_token': token,
          'name': user.userMetadata?['full_name'] ?? 'Driver',
          'type': type,
          'role': 'delivery_partner',
        },
      );
      print('FCMService: Edge Function response status: ${response.status}');
    } catch (e) {
      print('FCMService: Error invoking Edge Function: $e');
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
}
