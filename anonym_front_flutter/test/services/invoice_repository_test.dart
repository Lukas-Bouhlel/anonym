import 'package:anonym_front_flutter/services/invoice_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'repository_test_utils.dart';

void main() {
  group('InvoiceRepository', () {
    late MockDio dio;
    late InvoiceRepository repository;

    setUp(() {
      dio = MockDio();
      repository = InvoiceRepository(dio);
    });

    test('readAll and adminReadAll map payload list', () async {
      when(() => dio.get<List<dynamic>>('/api/invoice')).thenAnswer(
        (_) async => dioResponse<List<dynamic>>([
          {
            'id': 1,
            'user_id': 2,
            'article_id': 3,
            'type': 'SHOP',
            'amount': 9,
            'content': 'Order',
            'quantity': 1,
          },
        ], path: '/api/invoice'),
      );
      when(() => dio.get<List<dynamic>>('/api/invoice/admin/')).thenAnswer(
        (_) async => dioResponse<List<dynamic>>([
          {
            'id': 2,
            'user_id': 2,
            'article_id': 3,
            'type': 'SHOP',
            'amount': 9,
            'content': 'Admin',
            'quantity': 1,
          },
        ], path: '/api/invoice/admin/'),
      );

      final all = await repository.readAll();
      final adminAll = await repository.adminReadAll();
      expect(all, hasLength(1));
      expect(adminAll, hasLength(1));
    });

    test('sendInvoiceByEmail returns backend message with fallback', () async {
      when(() => dio.get<Map<String, dynamic>>('/api/invoice/7')).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>(
          {'message': 'sent'},
          path: '/api/invoice/7',
        ),
      );
      when(() => dio.get<Map<String, dynamic>>('/api/invoice/8')).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({}, path: '/api/invoice/8'),
      );

      final sent = await repository.sendInvoiceByEmail(7);
      final fallback = await repository.sendInvoiceByEmail(8);
      expect(sent, 'sent');
      expect(fallback, 'Facture envoyee');
    });

    test('adminCreate and adminUpdate parse nested invoice payload', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/invoice/admin/',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'invoice': {
            'id': 9,
            'user_id': 1,
            'article_id': 2,
            'type': 'SHOP',
            'amount': 10,
            'content': 'x',
            'quantity': 2,
          },
        }, path: '/api/invoice/admin/'),
      );
      when(
        () => dio.put<Map<String, dynamic>>(
          '/api/invoice/admin/9',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => dioResponse<Map<String, dynamic>>({
          'invoice': {
            'id': 9,
            'user_id': 2,
            'article_id': 3,
            'type': 'SHOP',
            'amount': 11,
            'content': 'y',
            'quantity': 3,
          },
        }, path: '/api/invoice/admin/9'),
      );
      when(() => dio.delete<void>('/api/invoice/admin/9')).thenAnswer(
        (_) async => dioResponse<void>(null, path: '/api/invoice/admin/9'),
      );

      final created = await repository.adminCreate(userId: 1, articleId: 2);
      final updated = await repository.adminUpdate(
        invoiceId: 9,
        userId: 2,
        articleId: 3,
        quantity: 3,
      );
      await repository.adminDelete(9);

      expect(created.id, 9);
      expect(updated.userId, 2);
      final updateBody = verify(
        () => dio.put<Map<String, dynamic>>(
          '/api/invoice/admin/9',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(updateBody, containsPair('quantity', 3));
    });
  });
}

