import 'package:anonym_front_flutter/models/live_user_location_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveUserLocationModel.fromJson', () {
    test('parses flat payload fields', () {
      final model = LiveUserLocationModel.fromJson({
        'userId': '10',
        'username': 'alice',
        'lat': '48.85',
        'lng': '2.35',
        'avatar': 'https://cdn.example.com/a.png',
        'updatedAt': '2026-05-01T12:00:00Z',
      });

      expect(model.userId, 10);
      expect(model.username, 'alice');
      expect(model.latitude, 48.85);
      expect(model.longitude, 2.35);
      expect(model.avatar, 'https://cdn.example.com/a.png');
      expect(model.updatedAt, isNotNull);
    });

    test('parses nested user and frame from inventories', () {
      final model = LiveUserLocationModel.fromJson({
        'user': {
          'id': 5,
          'username': 'bob',
          'avatar': 'https://cdn.example.com/b.png',
          'inventories': [
            {
              'active': true,
              'shop': {'type': 'CADRE', 'content': '/frames/border.png'},
            },
          ],
        },
        'latitude': 48.8566,
        'longitude': 2.3522,
      });

      expect(model.userId, 5);
      expect(model.username, 'bob');
      expect(model.avatar, 'https://cdn.example.com/b.png');
      expect(model.frameUrl, '/frames/border.png');
    });

    test('reads nested userId alias and pseudo values', () {
      final model = LiveUserLocationModel.fromJson({
        'user': {
          'userId': '17',
          'pseudo': 'PseudoName',
          'image': 'https://cdn.example.com/pseudo.png',
        },
        'position': {'lat': '12.34', 'lon': '56.78'},
      });

      expect(model.userId, 17);
      expect(model.username, 'PseudoName');
      expect(model.avatar, 'https://cdn.example.com/pseudo.png');
      expect(model.latitude, 12.34);
      expect(model.longitude, 56.78);
    });

    test('reads nested snake_case user_id alias', () {
      final model = LiveUserLocationModel.fromJson({
        'user': {'user_id': '29', 'username': 'snake'},
        'lat': 1,
        'lng': 2,
      });

      expect(model.userId, 29);
      expect(model.username, 'snake');
    });

    test('parses timestamp from positive int and num values', () {
      final fromInt = LiveUserLocationModel.fromJson({
        'userId': 1,
        'username': 'alice',
        'lat': 1,
        'lng': 2,
        'timestamp': 1735689600000,
      });
      final fromNum = LiveUserLocationModel.fromJson({
        'userId': 2,
        'username': 'bob',
        'lat': 1,
        'lng': 2,
        'timestamp': 1735689600000.0,
      });

      expect(fromInt.updatedAt, isNotNull);
      expect(fromNum.updatedAt, isNotNull);
    });

    test('returns null date for non-positive timestamp int and num', () {
      final fromInt = LiveUserLocationModel.fromJson({
        'userId': 1,
        'username': 'alice',
        'lat': 1,
        'lng': 2,
        'timestamp': 0,
      });
      final fromNum = LiveUserLocationModel.fromJson({
        'userId': 2,
        'username': 'bob',
        'lat': 1,
        'lng': 2,
        'timestamp': 0.0,
      });

      expect(fromInt.updatedAt, isNull);
      expect(fromNum.updatedAt, isNull);
    });

    test('parses frame from inventory map and active coercion', () {
      final fromNumericActive = LiveUserLocationModel.fromJson({
        'userId': 1,
        'username': 'alice',
        'lat': 1,
        'lng': 2,
        'inventories': {
          'active': 1,
          'shop': {'type': 'cadre', 'content': '/frames/one.png'},
        },
      });

      final fromStringActive = LiveUserLocationModel.fromJson({
        'userId': 2,
        'username': 'bob',
        'lat': 1,
        'lng': 2,
        'inventories': {
          'active': 'true',
          'shop': {'type': 'CADRE', 'content': '/frames/two.png'},
        },
      });

      expect(fromNumericActive.frameUrl, '/frames/one.png');
      expect(fromStringActive.frameUrl, '/frames/two.png');
    });

    test('ignores invalid inventory entries and inactive frames', () {
      final model = LiveUserLocationModel.fromJson({
        'userId': 3,
        'username': 'carol',
        'lat': 1,
        'lng': 2,
        'inventories': [
          'not-a-map',
          {
            'active': '0',
            'shop': {'type': 'CADRE', 'content': '/frames/inactive.png'},
          },
        ],
      });

      expect(model.frameUrl, isNull);
    });

    test('falls back to defaults when fields are missing', () {
      final model = LiveUserLocationModel.fromJson({});

      expect(model.userId, 0);
      expect(model.username, 'Utilisateur');
      expect(model.latitude, 0);
      expect(model.longitude, 0);
      expect(model.avatar, isNull);
      expect(model.frameUrl, isNull);
    });
  });

  group('LiveUserLocationModel.copyWith', () {
    test('copies and overrides selected values', () {
      const original = LiveUserLocationModel(
        userId: 1,
        username: 'alice',
        latitude: 10,
        longitude: 20,
      );

      final updated = original.copyWith(username: 'bob', latitude: 11);

      expect(updated.userId, 1);
      expect(updated.username, 'bob');
      expect(updated.latitude, 11);
      expect(updated.longitude, 20);
    });

    test('keeps original values when no overrides are provided', () {
      const original = LiveUserLocationModel(
        userId: 10,
        username: 'alice',
        avatar: 'https://cdn.example.com/a.png',
        frameUrl: 'https://cdn.example.com/f.png',
        latitude: 10,
        longitude: 20,
      );

      final copied = original.copyWith();

      expect(copied.userId, 10);
      expect(copied.username, 'alice');
      expect(copied.avatar, 'https://cdn.example.com/a.png');
      expect(copied.frameUrl, 'https://cdn.example.com/f.png');
      expect(copied.latitude, 10);
      expect(copied.longitude, 20);
    });
  });
}
