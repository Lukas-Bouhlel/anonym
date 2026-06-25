import 'package:anonym_front_flutter/utils/group_invite_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupInvitePayloadCodec.tryDecode', () {
    test('returns decoded payload for valid invite', () {
      const raw =
          'ANONYM_GROUP_INVITE:{"channelId":"12","channelName":"General","channelDescription":"Bienvenue","channelVisibility":"public","inviteCode":"XYZ","invitedByUserId":"8","invitedByUsername":"alice","channelCoverImage":"https://cdn.example.com/c.png"}';

      final payload = GroupInvitePayloadCodec.tryDecode(raw);

      expect(payload, isNotNull);
      expect(payload!.channelId, 12);
      expect(payload.channelName, 'General');
      expect(payload.channelDescription, 'Bienvenue');
      expect(payload.channelVisibility, 'PUBLIC');
      expect(payload.inviteCode, 'XYZ');
      expect(payload.invitedByUserId, 8);
      expect(payload.invitedByUsername, 'alice');
      expect(payload.channelCoverImage, 'https://cdn.example.com/c.png');
    });

    test('returns null if prefix is missing', () {
      expect(GroupInvitePayloadCodec.tryDecode('{"channelId":1}'), isNull);
    });

    test('returns null when payload body is empty', () {
      expect(
        GroupInvitePayloadCodec.tryDecode('ANONYM_GROUP_INVITE:  '),
        isNull,
      );
    });

    test('returns null when channel data is invalid', () {
      final invalidId = GroupInvitePayloadCodec.tryDecode(
        'ANONYM_GROUP_INVITE:{"channelId":0,"channelName":"General"}',
      );
      final emptyName = GroupInvitePayloadCodec.tryDecode(
        'ANONYM_GROUP_INVITE:{"channelId":1,"channelName":"   "}',
      );

      expect(invalidId, isNull);
      expect(emptyName, isNull);
    });
  });
}
