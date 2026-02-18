import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kisan_veer/models/notification_model.dart';
import 'package:kisan_veer/services/storage_service.dart';
import 'package:rxdart/rxdart.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final BehaviorSubject<NotificationModel?> notificationSubject =
      BehaviorSubject<NotificationModel?>();
  Stream<NotificationModel?> get notificationStream =>
      notificationSubject.stream;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StorageService _storageService = StorageService();
  final List<NotificationModel> _notificationHistory = [];
  bool _isInitialized = false;

  // Initialize local notifications
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      // Load notification history
      await _loadNotificationHistory();
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // General notifications
      const AndroidNotificationChannel generalChannel =
          AndroidNotificationChannel(
        'general_channel',
        'General Notifications',
        description: 'Channel for general notifications',
        importance: Importance.high,
      );

      // Weather alerts
      const AndroidNotificationChannel weatherChannel =
          AndroidNotificationChannel(
        'weather_channel',
        'Weather Alerts',
        description: 'Channel for weather alerts and forecasts',
        importance: Importance.high,
      );

      // Market price alerts
      const AndroidNotificationChannel marketChannel =
          AndroidNotificationChannel(
        'market_channel',
        'Market Alerts',
        description: 'Channel for market price alerts',
        importance: Importance.high,
      );

      // Community updates
      const AndroidNotificationChannel communityChannel =
          AndroidNotificationChannel(
        'community_channel',
        'Community Updates',
        description: 'Channel for community updates and discussion',
        importance: Importance.defaultImportance,
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(generalChannel);
        await androidPlugin.createNotificationChannel(weatherChannel);
        await androidPlugin.createNotificationChannel(marketChannel);
        await androidPlugin.createNotificationChannel(communityChannel);
      }
    }
  }

  // Handle when user taps on local notification
  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(payload);

        // Create notification model
        final notificationModel = NotificationModel(
          id: data['id'],
          title: data['title'],
          body: data['body'],
          timestamp: DateTime.parse(data['timestamp']),
          type: data['type'],
          read: true, // Mark as read since user tapped it
          data: data['data'],
        );

        // Update the notification as read in history
        _markAsRead(notificationModel.id);

        // Notify listeners to handle navigation
        notificationSubject.add(notificationModel);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Show a local notification
  Future<void> _showLocalNotification(
    String id,
    String title,
    String body,
    String type,
    Map<String, dynamic> data,
  ) async {
    // Prepare payload
    final Map<String, dynamic> payload = {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'type': type,
      'data': data,
    };

    String channelId;
    switch (type) {
      case 'weather':
        channelId = 'weather_channel';
        break;
      case 'market':
        channelId = 'market_channel';
        break;
      case 'community':
        channelId = 'community_channel';
        break;
      default:
        channelId = 'general_channel';
    }

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      type.toUpperCase(),
      channelDescription: 'Channel for $type notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      color: Colors.green,
    );

    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id.hashCode, // Use hash code to ensure unique IDs
      title,
      body,
      platformDetails,
      payload: json.encode(payload),
    );
  }

  // Send a local notification (used by the app for internal notifications)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Create notification model
    final notificationModel = NotificationModel(
      id: id,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      read: false,
      data: data ?? {},
    );

    // Add to history
    _notificationHistory.add(notificationModel);
    await _saveNotificationHistory();

    // Show notification
    await _showLocalNotification(
      id,
      title,
      body,
      type,
      data ?? {},
    );
  }

  // Send weather alert
  Future<void> sendWeatherAlert(
      String title, String body, Map<String, dynamic> weatherData) async {
    await showLocalNotification(
      title: title,
      body: body,
      type: 'weather',
      data: {'weatherData': weatherData},
    );
  }

  // Send market price alert
  Future<void> sendMarketAlert(
      String title, String body, String product, double price) async {
    await showLocalNotification(
      title: title,
      body: body,
      type: 'market',
      data: {'product': product, 'price': price},
    );
  }

  // Get the count of unread notifications
  Future<int> getUnreadNotificationsCount() async {
    await _loadNotificationHistory();
    return _notificationHistory
        .where((notification) => !notification.read)
        .length;
  }

  // Get all notifications
  Future<List<NotificationModel>> getNotifications() async {
    await _loadNotificationHistory();
    return List.from(_notificationHistory);
  }

  // Mark a notification as read
  Future<void> markAsRead(String id) async {
    await _markAsRead(id);
  }

  Future<void> _markAsRead(String id) async {
    final index = _notificationHistory.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notificationHistory[index] =
          _notificationHistory[index].copyWith(read: true);
      await _saveNotificationHistory();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notificationHistory.length; i++) {
      _notificationHistory[i] = _notificationHistory[i].copyWith(read: true);
    }
    await _saveNotificationHistory();
  }

  // Delete a notification
  Future<void> deleteNotification(String id) async {
    _notificationHistory.removeWhere((n) => n.id == id);
    await _saveNotificationHistory();
  }

  // Delete all notifications
  Future<void> clearAllNotifications() async {
    _notificationHistory.clear();
    await _saveNotificationHistory();
  }

  // Load notification history from storage
  Future<void> _loadNotificationHistory() async {
    final jsonString = await _storageService.getString('notification_history');
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _notificationHistory.clear();
      _notificationHistory.addAll(
        jsonList.map((json) => NotificationModel.fromJson(json)).toList(),
      );
    }
  }

  // Save notification history to storage
  Future<void> _saveNotificationHistory() async {
    final jsonList = _notificationHistory
        .map((notification) => notification.toJson())
        .toList();
    await _storageService.saveString(
        'notification_history', json.encode(jsonList));
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    await _loadNotificationHistory();
    return _notificationHistory.where((n) => !n.read).length;
  }

  // Clean up resources
  void dispose() {
    notificationSubject.close();
  }
}
