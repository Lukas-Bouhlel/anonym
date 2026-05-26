import 'package:anonym_front_flutter/models/app_notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotificationModel', () {
    test('copyWith updates isRead only', () {
      final base = AppNotificationModel(
        id: 'n1',
        type: AppNotificationType.newMessage,
        title: 't',
        subtitle: 's',
        createdAt: DateTime(2025, 1, 1),
      );

      final read = base.copyWith(isRead: true);

      expect(read.isRead, isTrue);
      expect(read.id, base.id);
      expect(read.type, base.type);
      expect(read.createdAt, base.createdAt);
    });
  });
}

