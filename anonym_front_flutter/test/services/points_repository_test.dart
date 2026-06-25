import 'package:anonym_front_flutter/services/points_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'repository_test_utils.dart';

void main() {
  group('PointsRepository', () {
    late MockDio dio;
    late PointsRepository repository;

    setUp(() {
      dio = MockDio();
      repository = PointsRepository(dio);
    });

    test('readMe sends period and formatted date query params', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/api/points/me',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'user': {
            'id': 1,
            'username': 'neo',
            'totalPoints': 0,
            'level': <String, dynamic>{},
          },
          'totals': {'messagesCount': 0, 'pointsEarned': 0},
          'history': const [],
        }, path: '/api/points/me'),
      );

      final summary = await repository.readMe(
        period: 'month',
        startDate: DateTime(2026, 1, 9),
      );

      expect(summary.user.id, 1);
      verify(
        () => dio.get<Map<String, dynamic>>(
          '/api/points/me',
          queryParameters: {
            'period': 'month',
            'startDate': '2026-01-09',
          },
        ),
      ).called(1);
    });
  });
}
