import 'package:anonym_front_flutter/services/payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'repository_test_utils.dart';

void main() {
  group('PaymentRepository', () {
    late MockDio dio;
    late PaymentRepository repository;

    setUp(() {
      dio = MockDio();
      repository = PaymentRepository(dio);
    });

    test('createCheckout returns url from payload', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/payment',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>(
          {'url': 'https://checkout.test'},
          path: '/api/payment',
        ),
      );

      final url = await repository.createCheckout(77);
      expect(url, 'https://checkout.test');
    });

    test('confirm parses payment confirmation payload', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/api/payment/confirm',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'message': 'ok',
          'invoice': {
            'id': 1,
            'user_id': 2,
            'article_id': 3,
            'type': 'SHOP',
            'amount': 4,
            'content': 'x',
            'quantity': 1,
          },
        }, path: '/api/payment/confirm'),
      );

      final result = await repository.confirm('sess_1');
      expect(result.message, 'ok');
      expect(result.invoice, isNotNull);
      verify(
        () => dio.get<Map<String, dynamic>>(
          '/api/payment/confirm',
          queryParameters: {'session_id': 'sess_1'},
        ),
      ).called(1);
    });
  });
}

