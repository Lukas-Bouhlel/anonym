import 'package:anonym_front_flutter/utils/api_error_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DioException dioWithData(Object? data, {String? message}) {
    final request = RequestOptions(path: '/test');
    return DioException(
      requestOptions: request,
      response: Response(requestOptions: request, data: data, statusCode: 400),
      message: message,
    );
  }

  group('ApiErrorParser.parse', () {
    test('reads message field from map payload', () {
      final error = dioWithData({'message': 'Invalid credentials'});
      final parsed = ApiErrorParser.parse(error, fallback: 'Fallback');
      expect(parsed, 'Invalid credentials');
    });

    test('reads list payload from error field', () {
      final error = dioWithData({
        'error': ['First issue', 'Second issue'],
      });
      final parsed = ApiErrorParser.parse(error, fallback: 'Fallback');
      expect(parsed, 'First issue\nSecond issue');
    });

    test('reads nested errors map', () {
      final error = dioWithData({
        'errors': {
          'email': ['Email invalide'],
          'password': 'Trop court',
        },
      });
      final parsed = ApiErrorParser.parse(error, fallback: 'Fallback');
      expect(parsed, 'Email invalide\nTrop court');
    });

    test('reads errors list from errors key', () {
      final error = dioWithData({
        'errors': ['Erreur 1', 'Erreur 2'],
      });
      final parsed = ApiErrorParser.parse(error, fallback: 'Fallback');
      expect(parsed, 'Erreur 1\nErreur 2');
    });

    test('falls back to response string when available', () {
      final error = dioWithData('Plain backend error');
      final parsed = ApiErrorParser.parse(error, fallback: 'Fallback');
      expect(parsed, 'Plain backend error');
    });

    test('falls back to dio message when response data is empty', () {
      final error = dioWithData(null, message: 'Socket timeout');
      final parsed = ApiErrorParser.parse(error, fallback: 'Fallback');
      expect(parsed, 'Socket timeout');
    });

    test('returns fallback for non-dio errors', () {
      final parsed = ApiErrorParser.parse(
        Exception('boom'),
        fallback: 'Fallback',
      );
      expect(parsed, 'Fallback');
    });
  });
}
