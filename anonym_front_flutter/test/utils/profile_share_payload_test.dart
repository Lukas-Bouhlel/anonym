import 'package:anonym_front_flutter/utils/profile_share_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileSharePayloadCodec.encode', () {
    test('encodes payload with prefix and trimmed values', () {
      final raw = ProfileSharePayloadCodec.encode(
        const ProfileSharePayload(
          userId: 42,
          username: '  Lukas  ',
          avatarUrl: ' https://cdn.example.com/avatar.png ',
          frameUrl: '  ',
        ),
      );

      expect(raw, startsWith('ANONYM_PROFILE_SHARE:'));
      expect(raw, contains('"userId":42'));
      expect(raw, contains('"username":"Lukas"'));
      expect(raw, contains('"avatarUrl":"https://cdn.example.com/avatar.png"'));
      expect(raw, isNot(contains('"frameUrl"')));
    });

    test('encodes frameUrl when provided', () {
      final raw = ProfileSharePayloadCodec.encode(
        const ProfileSharePayload(
          userId: 42,
          username: 'Lukas',
          frameUrl: ' https://cdn.example.com/frame.png ',
        ),
      );

      expect(raw, contains('"frameUrl":"https://cdn.example.com/frame.png"'));
    });
  });

  group('ProfileSharePayloadCodec.tryDecode', () {
    test('returns decoded payload for valid input', () {
      const encoded =
          'ANONYM_PROFILE_SHARE:{"userId":"7","username":"alice","avatarUrl":"https://cdn.example.com/a.png"}';

      final payload = ProfileSharePayloadCodec.tryDecode(encoded);

      expect(payload, isNotNull);
      expect(payload!.userId, 7);
      expect(payload.username, 'alice');
      expect(payload.avatarUrl, 'https://cdn.example.com/a.png');
      expect(payload.frameUrl, isNull);
    });

    test('returns null when prefix is missing', () {
      final payload = ProfileSharePayloadCodec.tryDecode('{"userId":1}');
      expect(payload, isNull);
    });

    test('returns null when payload body is empty', () {
      final payload = ProfileSharePayloadCodec.tryDecode(
        'ANONYM_PROFILE_SHARE:   ',
      );
      expect(payload, isNull);
    });

    test('returns null when userId or username is invalid', () {
      final missingUserId = ProfileSharePayloadCodec.tryDecode(
        'ANONYM_PROFILE_SHARE:{"username":"alice"}',
      );
      final missingUsername = ProfileSharePayloadCodec.tryDecode(
        'ANONYM_PROFILE_SHARE:{"userId":1,"username":""}',
      );

      expect(missingUserId, isNull);
      expect(missingUsername, isNull);
    });
  });
}
