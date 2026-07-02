import 'package:anonym_front_flutter/utils/app_config.dart';
import 'package:anonym_front_flutter/utils/media_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaUrl.nullable', () {
    test('returns null when input is empty', () {
      expect(MediaUrl.nullable('  '), isNull);
      expect(MediaUrl.nullable(null), isNull);
    });

    test('normalizes when input is non-empty', () {
      final normalized = MediaUrl.nullable('uploads/avatar.png');
      final expected = Uri.parse(
        AppConfig.apiBaseUrl,
      ).resolve('/uploads/avatar.png').toString();
      expect(normalized, expected);
    });
  });

  group('MediaUrl.normalize', () {
    test('returns empty value when raw is empty', () {
      expect(MediaUrl.normalize('   '), '');
    });

    test('keeps data and blob URLs unchanged', () {
      expect(
        MediaUrl.normalize('data:image/png;base64,abc'),
        startsWith('data:'),
      );
      expect(MediaUrl.normalize('blob:https://app/123'), startsWith('blob:'));
    });

    test('keeps external URL unchanged', () {
      const value = 'https://cdn.example.com/avatar.png';
      expect(MediaUrl.normalize(value), value);
    });

    test('rebases localhost URL to configured API host', () {
      final normalized = MediaUrl.normalize(
        'http://localhost:5000/uploads/avatar.png?x=1#frag',
      );
      final expected = Uri.parse(AppConfig.apiBaseUrl)
          .replace(path: '/uploads/avatar.png', query: 'x=1', fragment: 'frag')
          .toString();
      expect(normalized, expected);
    });

    test('rebases uploaded media URL even when host is not local', () {
      final normalized = MediaUrl.normalize(
        'http://51.75.18.155:5000/uploads/messages/images/pic.jpg',
      );
      final expected = Uri.parse(
        AppConfig.apiBaseUrl,
      ).replace(path: '/uploads/messages/images/pic.jpg').toString();
      expect(normalized, expected);
    });

    test('builds absolute URL for relative path', () {
      final normalized = MediaUrl.normalize('uploads/avatar.png');
      final expected = Uri.parse(
        AppConfig.apiBaseUrl,
      ).resolve('/uploads/avatar.png').toString();
      expect(normalized, expected);
    });
  });
}
