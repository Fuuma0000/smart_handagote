import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class Notification {
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'high_importance_channel', 'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high);

  Notification() {
    _setNotification();
    configureFirebaseMessaging();
  }

  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('バックグラウンドでメッセージを受け取りました');
  }

  Future<void> configureFirebaseMessaging() async {
    print('configureFirebaseMessaging');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification!;
      AndroidNotification android = message.notification!.android!;

      if (message.notification != null && android != null) {
        print('Message contained a notification: ${message.notification}');

        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                // channel.description,
                icon: 'launch_background',
              ),
            ));
      }
    });
  }

  Future<void> _setNotification() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .requestPermission();

    final messaging = FirebaseMessaging.instance;
    // FCMのトークンのIDを取得
    final fcmTocken = await messaging.getToken();
    print('fcmToken: $fcmTocken');

    // final FlutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void listenNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        var androidChannelSpecifics = const AndroidNotificationDetails(
          'CHANNEL_ID',
          'CHANNEL_NAME',
          channelDescription: "CHANNEL_DESCRIPTION",
          importance: Importance.max,
          priority: Priority.high,
          playSound: false,
          timeoutAfter: 5000,
          styleInformation: DefaultStyleInformation(true, true),
        );
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: androidChannelSpecifics,
          ),
        );
      }
    });
  }
}
