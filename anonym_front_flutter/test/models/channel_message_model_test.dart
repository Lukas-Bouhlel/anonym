import 'package:anonym_front_flutter/models/channel_message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChannelMessageModel', () {
    test('fromJson parses payload with sender and aliases', () {
      final model = ChannelMessageModel.fromJson({
        'message_id': '12',
        'Content': 'hello',
        'ChannelId': 77,
        'userSenderId': '5',
        'status': 'SENT',
        'createdAt': '2025-01-02T03:04:05Z',
        'image_url': '/img.png',
        'Sender': {
          'id': 5,
          'username': 'neo',
          'email': 'neo@test.dev',
        },
      });

      expect(model.messageId, 12);
      expect(model.content, 'hello');
      expect(model.channelId, 77);
      expect(model.senderId, 5);
      expect(model.status, 'SENT');
      expect(model.createdAt, isNotNull);
      expect(model.sender?.id, 5);
      expect(model.imageUrl, '/img.png');
    });

    test('fromJson falls back to sender id and default values', () {
      final model = ChannelMessageModel.fromJson({
        'id': 'bad',
        'channel_id': 'bad',
        'content': null,
        'createdAt': 'not-a-date',
        'user': {
          'id': 22,
          'username': 'u22',
          'email': 'u22@test.dev',
        },
      });

      expect(model.messageId, 0);
      expect(model.channelId, 0);
      expect(model.content, '');
      expect(model.senderId, 22);
      expect(model.createdAt, isNull);
      expect(model.imageUrl, isNull);
    });
  });
}

