import 'package:anonym_front_flutter/utils/app_config.dart';
import 'package:anonym_front_flutter/utils/group_invite_payload.dart';
import 'package:anonym_front_flutter/utils/media_url.dart';
import 'package:anonym_front_flutter/utils/profile_share_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaUrl edge cases', () {
    test('rebases loopback host URL to configured API host', () {
      final normalized = MediaUrl.normalize(
        'http://127.0.0.1:3000/uploads/pic.png?x=1',
      );
      final expected = Uri.parse(
        AppConfig.apiBaseUrl,
      ).replace(path: '/uploads/pic.png', query: 'x=1').toString();
      expect(normalized, expected);
    });
  });

  group('GroupInvitePayloadCodec edge cases', () {
    test('returns null on malformed json', () {
      final decoded = GroupInvitePayloadCodec.tryDecode(
        'ANONYM_GROUP_INVITE:{not-json',
      );
      expect(decoded, isNull);
    });

    test('maps blank cover image to null', () {
      const raw =
          'ANONYM_GROUP_INVITE:{"channelId":1,"channelName":"General","channelCoverImage":"   "}';
      final decoded = GroupInvitePayloadCodec.tryDecode(raw);
      expect(decoded, isNotNull);
      expect(decoded!.channelCoverImage, isNull);
    });
  });

  group('ProfileSharePayloadCodec edge cases', () {
    test('decodes frameUrl when present', () {
      const raw =
          'ANONYM_PROFILE_SHARE:{"userId":42,"username":"neo","frameUrl":"https://cdn.example.com/frame.png"}';
      final decoded = ProfileSharePayloadCodec.tryDecode(raw);

      expect(decoded, isNotNull);
      expect(decoded!.frameUrl, 'https://cdn.example.com/frame.png');
    });
  });
}

