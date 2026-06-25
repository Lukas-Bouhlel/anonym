import 'package:anonym_front_flutter/services/private_message_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'repository_test_utils.dart';

void main() {
  group('PrivateMessageRepository', () {
    late MockDio dio;
    late PrivateMessageRepository repository;

    setUp(() {
      dio = MockDio();
      repository = PrivateMessageRepository(dio);
    });

    test('sendWithImage supports bytes upload and parses message', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/privateMessage/5/send',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'message_id': 1,
          'content': 'hello',
          'channel_id': 5,
        }, path: '/api/privateMessage/5/send'),
      );

      final result = await repository.sendWithImage(
        channelId: 5,
        content: ' hello ',
        imageBytes: [1, 2, 3],
        imageFileName: 'img.jpg',
      );

      expect(result.messageId, 1);
      expect(result.content, 'hello');
    });

    test('update and delete call expected endpoints', () async {
      when(
        () => dio.put<Map<String, dynamic>>(
          '/api/privateMessage/9',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'message_id': 9,
          'content': 'updated',
          'channel_id': 5,
        }, path: '/api/privateMessage/9'),
      );
      when(
        () => dio.delete<void>('/api/privateMessage/9'),
      ).thenAnswer((_) async => dioResponse<void>(null, path: '/api/privateMessage/9'));

      final updated = await repository.update(messageId: 9, content: 'updated');
      await repository.delete(9);

      expect(updated.messageId, 9);
      verify(() => dio.delete<void>('/api/privateMessage/9')).called(1);
    });
  });
}

