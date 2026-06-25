import 'package:anonym_front_flutter/models/live_user_location_model.dart';
import 'package:anonym_front_flutter/widgets/anonym_map/anonym_map_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildAnonymMapMarkers', () {
    test('builds one marker for a single user and labels self as Moi', () {
      const locations = [
        LiveUserLocationModel(
          userId: 9,
          username: 'alice',
          latitude: 48.8566,
          longitude: 2.3522,
        ),
      ];

      final markers = buildAnonymMapMarkers(locations, 9);

      expect(markers, hasLength(1));
      expect(markers.first.label, 'Moi');
      expect(markers.first.members, hasLength(1));
      expect(markers.first.members.first.initials, 'A');
      expect(markers.first.key, contains('self:9|'));
    });

    test('clusters nearby users and keeps deterministic member order', () {
      const locations = [
        LiveUserLocationModel(
          userId: 2,
          username: 'Bob',
          latitude: 48.8566,
          longitude: 2.3522,
        ),
        LiveUserLocationModel(
          userId: 1,
          username: 'Alice',
          latitude: 48.8567,
          longitude: 2.35225,
        ),
      ];

      final markers = buildAnonymMapMarkers(locations, null);

      expect(markers, hasLength(1));
      expect(markers.first.members, hasLength(2));
      expect(markers.first.members.first.userId, 1);
      expect(markers.first.members.last.userId, 2);
      expect(markers.first.label, 'Alice & Bob');
    });

    test('formats labels for 3 and 4 members', () {
      const close = [
        LiveUserLocationModel(
          userId: 1,
          username: 'Alice',
          latitude: 48.8566,
          longitude: 2.3522,
        ),
        LiveUserLocationModel(
          userId: 2,
          username: 'Bob',
          latitude: 48.85661,
          longitude: 2.35221,
        ),
        LiveUserLocationModel(
          userId: 3,
          username: 'Carol',
          latitude: 48.85662,
          longitude: 2.35222,
        ),
      ];
      final markers3 = buildAnonymMapMarkers(close, null);
      expect(markers3.first.label, 'Alice, Bob & Carol');

      const close4 = [
        LiveUserLocationModel(
          userId: 1,
          username: 'Alice',
          latitude: 48.8566,
          longitude: 2.3522,
        ),
        LiveUserLocationModel(
          userId: 2,
          username: 'Bob',
          latitude: 48.85661,
          longitude: 2.35221,
        ),
        LiveUserLocationModel(
          userId: 3,
          username: 'Carol',
          latitude: 48.85662,
          longitude: 2.35222,
        ),
        LiveUserLocationModel(
          userId: 4,
          username: 'Dave',
          latitude: 48.85663,
          longitude: 2.35223,
        ),
      ];
      final markers4 = buildAnonymMapMarkers(close4, null);
      expect(markers4.first.label, 'Alice, Bob...');
    });

    test('creates separate markers for distant users', () {
      const locations = [
        LiveUserLocationModel(
          userId: 1,
          username: 'Alice',
          latitude: 48.8566,
          longitude: 2.3522,
        ),
        LiveUserLocationModel(
          userId: 2,
          username: 'Bob',
          latitude: 43.2965,
          longitude: 5.3698,
        ),
      ];

      final markers = buildAnonymMapMarkers(locations, null);
      expect(markers, hasLength(2));
    });
  });

  group('anonymMapMarkerFingerprint', () {
    test('concatenates marker keys in order', () {
      const markers = [
        AnonymMapMarkerData(
          key: 'a|',
          latitude: 0,
          longitude: 0,
          label: 'A',
          members: [],
        ),
        AnonymMapMarkerData(
          key: 'b|',
          latitude: 1,
          longitude: 1,
          label: 'B',
          members: [],
        ),
      ];

      final fingerprint = anonymMapMarkerFingerprint(markers);
      expect(fingerprint, 'a||b||');
    });
  });

  group('anonymMapColorForUser', () {
    test('returns deterministic color by user id modulo palette', () {
      expect(anonymMapColorForUser(0), const Color(0xFF393566));
      expect(anonymMapColorForUser(6), const Color(0xFF393566));
      expect(anonymMapColorForUser(-1), const Color(0xFF8E97F8));
    });
  });

  group('AnonymMapMarkerData.toJson', () {
    test('serializes members and fallback color', () {
      const member = AnonymMapMarkerMember(
        userId: 7,
        username: 'alice',
        initials: '?',
        fallbackColor: Color(0xFF393566),
        avatarUrl: null,
        frameUrl: null,
      );
      const data = AnonymMapMarkerData(
        key: 'k',
        latitude: 1,
        longitude: 2,
        label: 'L',
        members: [member],
      );

      final json = data.toJson();
      final members = json['members'] as List<dynamic>;
      final first = members.first as Map<String, Object?>;

      expect(json['key'], 'k');
      expect(first['fallbackColor'], '#393566');
      expect(first['initials'], '?');
    });
  });
}

