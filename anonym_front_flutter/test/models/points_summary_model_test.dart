import 'package:anonym_front_flutter/models/points_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PointsSummaryModel', () {
    test('fromJson parses nested structures and history', () {
      final model = PointsSummaryModel.fromJson({
        'period': 'week',
        'periodSelection': 'manual',
        'range': {
          'startDate': '2025-01-01',
          'endDate': '2025-01-07',
        },
        'user': {
          'id': '10',
          'username': 'neo',
          'totalPoints': 100.0,
          'level': {
            'level': 2,
            'maxLevel': 10,
            'totalPoints': 100,
            'currentLevelThreshold': 50,
            'nextLevelThreshold': 150,
            'pointsIntoLevel': 50,
            'pointsNeededForNextLevel': 100,
            'pointsRemainingForNextLevel': 50,
            'isMaxLevel': false,
          },
        },
        'totals': {
          'messagesCount': '4',
          'pointsEarned': '20',
        },
        'history': [
          {
            'bucket': '2025-01-01',
            'messagesCount': 1,
            'pointsEarned': 5,
          },
        ],
      });

      expect(model.period, 'week');
      expect(model.periodSelection, 'manual');
      expect(model.range.startDate, isNotNull);
      expect(model.user.id, 10);
      expect(model.user.totalPoints, 100);
      expect(model.user.level.level, 2);
      expect(model.user.level.completionRatio, 0.5);
      expect(model.totals.messagesCount, 4);
      expect(model.totals.pointsEarned, 20);
      expect(model.history, hasLength(1));
    });

    test('completionRatio handles max level and invalid denominator', () {
      const maxed = PointsLevelModel(
        level: 99,
        maxLevel: 99,
        totalPoints: 1000,
        currentLevelThreshold: 0,
        nextLevelThreshold: 0,
        pointsIntoLevel: 0,
        pointsNeededForNextLevel: 0,
        pointsRemainingForNextLevel: 0,
        isMaxLevel: true,
      );
      const broken = PointsLevelModel(
        level: 1,
        maxLevel: 10,
        totalPoints: 0,
        currentLevelThreshold: 0,
        nextLevelThreshold: 0,
        pointsIntoLevel: 10,
        pointsNeededForNextLevel: 0,
        pointsRemainingForNextLevel: 0,
        isMaxLevel: false,
      );

      expect(maxed.completionRatio, 1);
      expect(broken.completionRatio, 0);
    });

    test('fromJson falls back to defaults for missing payload', () {
      final model = PointsSummaryModel.fromJson({});
      expect(model.period, 'day');
      expect(model.periodSelection, 'auto');
      expect(model.user.id, 0);
      expect(model.user.username, '');
      expect(model.history, isEmpty);
    });
  });
}

