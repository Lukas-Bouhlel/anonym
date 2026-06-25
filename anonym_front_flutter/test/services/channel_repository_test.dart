import 'dart:io';

import 'package:anonym_front_flutter/services/channel_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'repository_test_utils.dart';

void main() {
  group('ChannelRepository', () {
    late MockDio dio;
    late ChannelRepository repository;

    setUp(() {
      dio = MockDio();
      repository = ChannelRepository(dio);
    });

    test('create posts to /api/channels and parses response', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/channels',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'channel_id': 1,
          'name': 'General',
          'created_by': 9,
        }, path: '/api/channels'),
      );

      final result = await repository.create(
        channelType: 'GROUP',
        name: 'General',
        description: 'desc',
      );

      expect(result.channelId, 1);
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/api/channels',
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('create falls back to /api/channel on 404', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/channels',
          data: any(named: 'data'),
        ),
      ).thenThrow(dioException(path: '/api/channels', statusCode: 404));
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/channel',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'channel_id': 4,
          'name': 'Legacy',
          'created_by': 1,
        }, path: '/api/channel'),
      );

      final result = await repository.create(channelType: 'GROUP');
      expect(result.channelId, 4);
    });

    test('create with image retries without image when cover_image fails', () async {
      final tempDir = await Directory.systemTemp.createTemp('channel_repo_test_');
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });
      final imagePath = '${tempDir.path}/cover.png';
      await File(imagePath).writeAsBytes([1, 2, 3]);

      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/channels',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        dioException(
          path: '/api/channels',
          statusCode: 400,
          data: {'message': 'cover_image invalid'},
        ),
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/channels',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'channel_id': 8,
          'name': 'RetryNoImage',
          'created_by': 2,
        }, path: '/api/channels'),
      );

      final result = await repository.create(
        channelType: 'GROUP',
        imageFilePath: imagePath,
      );

      expect(result.channelId, 8);
    });

    test('invite and removeMember fallback to legacy endpoints', () async {
      when(
        () => dio.post<void>('/api/channels/invite', data: any(named: 'data')),
      ).thenThrow(dioException(path: '/api/channels/invite', statusCode: 405));
      when(
        () => dio.post<void>('/api/channel/invite', data: any(named: 'data')),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/channel/invite'));

      when(
        () => dio.delete<void>('/api/channels/1/members/2'),
      ).thenThrow(dioException(path: '/api/channels/1/members/2', statusCode: 404));
      when(
        () => dio.delete<void>('/api/channel/1/members/2'),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/channel/1/members/2'));

      await repository.invite(channelId: 1, userId: 2);
      await repository.removeMember(channelId: 1, userId: 2);
    });

    test('readUserChannels parses response and supports fallback', () async {
      when(
        () => dio.get<List<dynamic>>(
          '/api/channels/user',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(dioException(path: '/api/channels/user', statusCode: 404));
      when(
        () => dio.get<List<dynamic>>(
          '/api/channel/user',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<List<dynamic>>([
          {'channel_id': 11, 'name': 'Legacy', 'created_by': 1},
        ], path: '/api/channel/user'),
      );

      final channels = await repository.readUserChannels(filter: 'JOINED');
      expect(channels, hasLength(1));
      expect(channels.first.channelId, 11);
    });

    test('readPublicChannels uses explicit public endpoint when readUserChannels fails', () async {
      when(
        () => dio.get<List<dynamic>>(
          '/api/channels/user',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(dioException(path: '/api/channels/user', statusCode: 500));
      when(
        () => dio.get<List<dynamic>>('/api/channels/public'),
      ).thenThrow(dioException(path: '/api/channels/public', statusCode: 404));
      when(
        () => dio.get<List<dynamic>>('/api/channel/public'),
      ).thenAnswer(
        (_) async => dioResponse<List<dynamic>>([
          {'channel_id': 12, 'name': 'Public', 'created_by': 2},
        ], path: '/api/channel/public'),
      );

      final channels = await repository.readPublicChannels();
      expect(channels, hasLength(1));
      expect(channels.first.channelId, 12);
    });

    test('readUnreadCount readChannelUsers and readChannelMessages handle legacy fallback', () async {
      when(
        () => dio.get<Map<String, dynamic>>('/api/channels/1/unreadCount'),
      ).thenThrow(dioException(path: '/api/channels/1/unreadCount', statusCode: 405));
      when(
        () => dio.get<Map<String, dynamic>>('/api/channel/1/unreadCount'),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>(
          {'count': '9'},
          path: '/api/channel/1/unreadCount',
        ),
      );

      when(
        () => dio.get<List<dynamic>>('/api/channels/1/users'),
      ).thenThrow(dioException(path: '/api/channels/1/users', statusCode: 404));
      when(
        () => dio.get<List<dynamic>>('/api/channel/1/users'),
      ).thenAnswer(
        (_) async => dioResponse<List<dynamic>>([
          {'id': 3, 'username': 'u3', 'email': 'u3@test.dev'},
        ], path: '/api/channel/1/users'),
      );

      when(
        () => dio.get<dynamic>('/api/channels/1/messages'),
      ).thenAnswer((_) async => dioResponse<dynamic>('invalid', path: '/api/channels/1/messages'));

      final unread = await repository.readUnreadCount(1);
      final users = await repository.readChannelUsers(1);
      final messages = await repository.readChannelMessages(1);

      expect(unread, 9);
      expect(users, hasLength(1));
      expect(messages, isEmpty);
    });

    test('leave delete joinPublic fallback to legacy paths', () async {
      when(
        () => dio.delete<void>('/api/channels/leave/7'),
      ).thenThrow(dioException(path: '/api/channels/leave/7', statusCode: 404));
      when(
        () => dio.delete<void>('/api/channel/leave/7'),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/channel/leave/7'));

      when(
        () => dio.delete<void>('/api/channels/7'),
      ).thenThrow(dioException(path: '/api/channels/7', statusCode: 405));
      when(
        () => dio.delete<void>('/api/channel/7'),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/channel/7'));

      when(
        () => dio.post<void>('/api/channels/7/join-public', data: any(named: 'data')),
      ).thenThrow(dioException(path: '/api/channels/7/join-public', statusCode: 404));
      when(
        () => dio.post<void>('/api/channel/7/join-public', data: any(named: 'data')),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/channel/7/join-public'));

      await repository.leaveChannel(7);
      await repository.deleteChannel(7);
      await repository.joinPublic(7);
    });

    test('updateCover falls back to legacy endpoint on 404', () async {
      final tempDir = await Directory.systemTemp.createTemp('channel_cover_test_');
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });
      final imagePath = '${tempDir.path}/cover.png';
      await File(imagePath).writeAsBytes([1, 2, 3]);

      when(
        () => dio.put<void>(
          '/api/channels/6/cover',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(dioException(path: '/api/channels/6/cover', statusCode: 404));
      when(
        () => dio.put<void>(
          '/api/channel/6/cover',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/channel/6/cover'));

      await repository.updateCover(channelId: 6, imageFilePath: imagePath);
    });

    test('updateGroup returns early when payload is empty', () async {
      await repository.updateGroup(channelId: 1);
      verifyNever(
        () => dio.put<void>('/api/channels/1', data: any(named: 'data')),
      );
    });

    test('updateGroup retries patch and legacy endpoints', () async {
      when(
        () => dio.put<void>('/api/channels/2', data: any(named: 'data')),
      ).thenThrow(dioException(path: '/api/channels/2', statusCode: 500));
      when(
        () => dio.patch<void>('/api/channels/2', data: any(named: 'data')),
      ).thenThrow(dioException(path: '/api/channels/2', statusCode: 404));
      when(
        () => dio.put<void>('/api/channel/2', data: any(named: 'data')),
      ).thenThrow(dioException(path: '/api/channel/2', statusCode: 500));
      when(
        () => dio.patch<void>('/api/channel/2', data: any(named: 'data')),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/channel/2'));

      await repository.updateGroup(channelId: 2, name: 'n');
    });

    test('joinByInvite and createInviteLink support legacy fallback', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/channels/join-by-invite',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        dioException(path: '/api/channels/join-by-invite', statusCode: 405),
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/channel/join-by-invite',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>(
          {'channel_id': '44'},
          path: '/api/channel/join-by-invite',
        ),
      );

      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/channels/4/invite-links',
          data: any(named: 'data'),
        ),
      ).thenThrow(dioException(path: '/api/channels/4/invite-links', statusCode: 404));
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/channel/4/invite-links',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>(
          {'code': 'ABC'},
          path: '/api/channel/4/invite-links',
        ),
      );

      final joinedId = await repository.joinByInvite('CODE');
      final invite = await repository.createInviteLink(
        channelId: 4,
        mode: 'single_use',
        expiresInMinutes: 30,
      );

      expect(joinedId, 44);
      expect(invite['code'], 'ABC');
    });
  });
}
