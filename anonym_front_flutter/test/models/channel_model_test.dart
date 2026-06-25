import 'package:anonym_front_flutter/models/channel_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChannelModel', () {
    test('fromJson parses main fields and dmPeer', () {
      final model = ChannelModel.fromJson({
        'channel_id': '7',
        'name': 'General',
        'description': 'chat',
        'created_by': 2.0,
        'unreadCount': '3',
        'channel_type': 'DM',
        'visibility': 'PRIVATE',
        'reputation_score': '12',
        'cover_image': '/cover.png',
        'is_joined': '1',
        'list_category': 'joined',
        'dm_peer': {
          'id': 9,
          'username': 'alice',
          'email': 'a@test.dev',
        },
      });

      expect(model.channelId, 7);
      expect(model.createdBy, 2);
      expect(model.unreadCount, 3);
      expect(model.channelType, 'DM');
      expect(model.visibility, 'PRIVATE');
      expect(model.reputationScore, 12);
      expect(model.coverImage, isNotNull);
      expect(model.isJoined, isTrue);
      expect(model.listCategory, 'joined');
      expect(model.dmPeer?.id, 9);
    });

    test('fromJson applies fallback values', () {
      final model = ChannelModel.fromJson({
        'channelId': 'x',
        'createdBy': 'x',
        'count': null,
        'reputationScore': 'x',
        'isJoined': '0',
      });

      expect(model.channelId, 0);
      expect(model.name, '');
      expect(model.createdBy, 0);
      expect(model.unreadCount, 0);
      expect(model.reputationScore, isNull);
      expect(model.isJoined, isFalse);
      expect(model.visibility, 'PUBLIC');
      expect(model.dmPeer, isNull);
    });

    test('copyWith keeps old values when null', () {
      const source = ChannelModel(channelId: 1, name: 'n', createdBy: 2);
      final copy = source.copyWith(name: 'updated');
      expect(copy.channelId, 1);
      expect(copy.name, 'updated');
      expect(copy.createdBy, 2);
    });
  });
}

