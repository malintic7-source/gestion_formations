import 'package:flutter/foundation.dart';
import 'package:gestion_formations/Models/notification.dart';
import 'package:gestion_formations/Services/db_services.dart';

class NotificationsService {
  final LocalDataService _db = LocalDataService();

  Stream<List<AppNotification>> watchNotificationsForUser({
    required String userId,
    required String userEmail,
    required String userRole,
  }) {
    return _db.watchNotifications().map((notifications) {
      return notifications.where((notification) {
        final roleMatch = notification.targetRoles.contains(userRole);
        final userMatch = notification.targetUserIds.contains(userId);
        final audienceMatch = notification.audience.contains(userEmail);
        final isTargeted = notification.targetRoles.isNotEmpty ||
            notification.targetUserIds.isNotEmpty ||
            notification.audience.isNotEmpty;

        final shouldShow = !isTargeted || roleMatch || userMatch || audienceMatch;
        return shouldShow;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Stream<List<AppNotification>> watchAllNotifications() {
    return _db.watchNotifications().map((notifications) {
      final list = List<AppNotification>.from(notifications);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> createNotification({
    required String title,
    required String description,
    String? imageUrl,
    required String senderId,
    required String senderEmail,
    required List<String> targetRoles,
    required List<String> targetUserIds,
    required List<String> audience,
  }) async {
    final now = DateTime.now();
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      imageUrl: imageUrl,
      senderId: senderId,
      senderEmail: senderEmail,
      targetRoles: targetRoles,
      targetUserIds: targetUserIds,
      audience: audience,
      readBy: [],
      reminderCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    await _db.addNotification(notification);
  }

  Future<void> updateNotification({
    required String notificationId,
    required String title,
    required String description,
    String? imageUrl,
    required List<String> targetRoles,
    required List<String> targetUserIds,
    required List<String> audience,
  }) async {
    // Local update notification logic
    debugPrint('Notification mise à jour: $notificationId');
  }

  Future<void> remindNotification({
    required String notificationId,
    required List<String> targetUserIds,
  }) async {
    debugPrint('Relance notification envoyée pour: $notificationId');
  }

  Future<void> markNotificationRead({
    required String notificationId,
    required String userId,
  }) async {
    await _db.markNotificationRead(notificationId, userId);
  }

  Future<void> deleteNotification(String notificationId) async {
    debugPrint('Notification supprimée: $notificationId');
  }
}
