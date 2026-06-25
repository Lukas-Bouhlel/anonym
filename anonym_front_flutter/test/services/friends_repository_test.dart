import 'package:anonym_front_flutter/services/friends_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'repository_test_utils.dart';

void main() {
  group('FriendsRepository', () {
    late MockDio dio;
    late FriendsRepository repository;

    setUp(() {
      dio = MockDio();
      repository = FriendsRepository(dio);
    });

    test('read lists map payloads to models', () async {
      when(() => dio.get<List<dynamic>>('/api/friends')).thenAnswer(
        (_) async => dioResponse<List<dynamic>>([
          {
            'id': 1,
            'user_id': 1,
            'friend_id': 2,
            'status': 'ACTIVE',
          },
        ], path: '/api/friends'),
      );
      when(
        () => dio.get<List<dynamic>>('/api/friends/requests/incoming'),
      ).thenAnswer((_) async => dioResponse<List<dynamic>>([], path: '/api/friends/requests/incoming'));
      when(
        () => dio.get<List<dynamic>>('/api/friends/requests/outgoing'),
      ).thenAnswer((_) async => dioResponse<List<dynamic>>([], path: '/api/friends/requests/outgoing'));

      final all = await repository.readAll();
      final incoming = await repository.readIncomingRequests();
      final outgoing = await repository.readOutgoingRequests();

      expect(all, hasLength(1));
      expect(all.first.friendId, 2);
      expect(incoming, isEmpty);
      expect(outgoing, isEmpty);
    });

    test('readById and addByUsername parse payload', () async {
      when(() => dio.get<Map<String, dynamic>>('/api/friends/8')).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'id': 8,
          'user_id': 1,
          'friend_id': 2,
          'status': 'ACTIVE',
        }, path: '/api/friends/8'),
      );
      when(
        () => dio.post<Map<String, dynamic>>('/api/friends/alice'),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'id': 9,
          'user_id': 1,
          'friend_id': 3,
          'status': 'PENDING',
        }, path: '/api/friends/alice'),
      );

      final byId = await repository.readById(8);
      final created = await repository.addByUsername('alice');

      expect(byId.id, 8);
      expect(created, isNotNull);
      expect(created?.status, 'PENDING');
    });

    test('addByUsername handles empty payload map', () async {
      when(
        () => dio.post<Map<String, dynamic>>('/api/friends/nobody'),
      ).thenAnswer(
        (_) async =>
            dioResponse<Map<String, dynamic>>({}, path: '/api/friends/nobody'),
      );

      final result = await repository.addByUsername('nobody');
      expect(result, isNotNull);
      expect(result?.id, 0);
    });

    test('updateStatus delete block and unblock call expected endpoints', () async {
      when(
        () => dio.put<void>('/api/friends/5', data: any(named: 'data')),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/friends/5'));
      when(
        () => dio.delete<void>('/api/friends/5'),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/friends/5'));
      when(
        () => dio.post<void>('/api/friends/5/block'),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/friends/5/block'));
      when(
        () => dio.delete<void>('/api/friends/5/block'),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/friends/5/block'));

      await repository.updateStatus(friendId: 5, status: 'ACTIVE');
      await repository.deleteById(5);
      await repository.blockUserById(5);
      await repository.unblockUserById(5);

      verify(() => dio.put<void>('/api/friends/5', data: any(named: 'data'))).called(1);
      verify(() => dio.delete<void>('/api/friends/5')).called(1);
      verify(() => dio.post<void>('/api/friends/5/block')).called(1);
      verify(() => dio.delete<void>('/api/friends/5/block')).called(1);
    });

    test('respondToRequest swallows already handled 404 errors', () async {
      when(
        () => dio.put<void>(
          '/api/friends/requests/22/respond',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        dioException(
          path: '/api/friends/requests/22/respond',
          statusCode: 404,
          data: {'message': 'Friend request not found'},
        ),
      );

      await repository.respondToRequest(requestId: 22, status: 'ACCEPTED');
    });

    test('respondToRequest rethrows non handled errors', () async {
      when(
        () => dio.put<void>(
          '/api/friends/requests/23/respond',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        dioException(
          path: '/api/friends/requests/23/respond',
          statusCode: 500,
          data: {'message': 'boom'},
        ),
      );

      await expectLater(
        repository.respondToRequest(requestId: 23, status: 'ACCEPTED'),
        throwsA(isA<DioException>()),
      );
    });

    test('cancelOutgoingRequest swallows already handled 404 errors', () async {
      when(
        () => dio.delete<void>('/api/friends/requests/24'),
      ).thenThrow(
        dioException(
          path: '/api/friends/requests/24',
          statusCode: 404,
          data: {'message': 'introuvable'},
        ),
      );

      await repository.cancelOutgoingRequest(24);
    });

    test('readBlockedUsers maps details and fallback user', () async {
      when(
        () => dio.get<List<dynamic>>('/api/friends/blocked'),
      ).thenAnswer(
        (_) async => dioResponse<List<dynamic>>([
          {
            'friend': {
              'id': 99,
              'username': 'blocked',
              'email': 'b@test.dev',
            },
          },
          {'friend': 'invalid'},
        ], path: '/api/friends/blocked'),
      );

      final result = await repository.readBlockedUsers();
      expect(result, hasLength(2));
      expect(result.first.id, 99);
      expect(result.last.username, 'Utilisateur');
    });
  });
}
