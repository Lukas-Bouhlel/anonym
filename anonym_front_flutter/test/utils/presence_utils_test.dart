import 'package:anonym_front_flutter/utils/presence_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PresenceUtils.normalize', () {
    test('returns normalized known status', () {
      expect(PresenceUtils.normalize(' Online '), PresenceUtils.online);
    });

    test('falls back to offline for unknown values', () {
      expect(PresenceUtils.normalize('busy'), PresenceUtils.offline);
    });
  });

  group('PresenceUtils.effectiveForViewer', () {
    test('maps invisible to offline for other users', () {
      final status = PresenceUtils.effectiveForViewer(
        PresenceUtils.invisible,
        isCurrentUser: false,
      );
      expect(status, PresenceUtils.offline);
    });

    test('keeps invisible for current user', () {
      final status = PresenceUtils.effectiveForViewer(
        PresenceUtils.invisible,
        isCurrentUser: true,
      );
      expect(status, PresenceUtils.invisible);
    });
  });

  group('PresenceUtils.label', () {
    test('returns expected localized labels', () {
      expect(
        PresenceUtils.label(PresenceUtils.online, isCurrentUser: false),
        'En ligne',
      );
      expect(
        PresenceUtils.label(PresenceUtils.idle, isCurrentUser: false),
        'Inactif',
      );
      expect(
        PresenceUtils.label(PresenceUtils.dnd, isCurrentUser: false),
        'Ne pas deranger',
      );
      expect(
        PresenceUtils.label(PresenceUtils.invisible, isCurrentUser: true),
        'Invisible',
      );
      expect(
        PresenceUtils.label(PresenceUtils.invisible, isCurrentUser: false),
        'Hors ligne',
      );
    });
  });
}
