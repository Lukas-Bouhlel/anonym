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
      final parsed = ApiErrorParser.parse(
        error,
        fallback: 'Fallback',
        exposeBackendDetails: true,
      );
      expect(parsed, 'Invalid credentials');
    });

    test('reads list payload from error field', () {
      final error = dioWithData({
        'error': ['First issue', 'Second issue'],
      });
      final parsed = ApiErrorParser.parse(
        error,
        fallback: 'Fallback',
        exposeBackendDetails: true,
      );
      expect(parsed, 'First issue\nSecond issue');
    });

    test('reads nested errors map', () {
      final error = dioWithData({
        'errors': {
          'email': ['Email invalide'],
          'password': 'Trop court',
        },
      });
      final parsed = ApiErrorParser.parse(
        error,
        fallback: 'Fallback',
        exposeBackendDetails: true,
      );
      expect(parsed, 'Email invalide\nTrop court');
    });

    test('reads errors list from errors key', () {
      final error = dioWithData({
        'errors': ['Erreur 1', 'Erreur 2'],
      });
      final parsed = ApiErrorParser.parse(
        error,
        fallback: 'Fallback',
        exposeBackendDetails: true,
      );
      expect(parsed, 'Erreur 1\nErreur 2');
    });

    test('falls back to response string when available', () {
      final error = dioWithData('Plain backend error');
      final parsed = ApiErrorParser.parse(
        error,
        fallback: 'Fallback',
        exposeBackendDetails: true,
      );
      expect(parsed, 'Plain backend error');
    });

    test('falls back to dio message when response data is empty', () {
      final error = dioWithData(null, message: 'Socket timeout');
      final parsed = ApiErrorParser.parse(
        error,
        fallback: 'Fallback',
        exposeBackendDetails: true,
      );
      expect(parsed, 'Socket timeout');
    });

    test('returns fallback for non-dio errors', () {
      final parsed = ApiErrorParser.parse(
        Exception('boom'),
        fallback: 'Fallback',
      );
      expect(parsed, 'Fallback');
    });

    test('sanitizes unauthorized error when backend details are hidden', () {
      final request = RequestOptions(path: '/login');
      final error = DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          data: {'message': 'Invalid credentials for user admin@corp'},
          statusCode: 401,
        ),
      );
      final parsed = ApiErrorParser.parse(
        error,
        fallback: 'Connexion impossible',
        exposeBackendDetails: false,
      );
      expect(parsed, 'Authentification echouee.');
    });

    test('uses fallback for client errors when backend details are hidden', () {
      final parsed = ApiErrorParser.parse(
        dioWithData({'message': 'Email already used'}),
        fallback: 'Inscription impossible',
        exposeBackendDetails: false,
      );
      expect(parsed, 'Inscription impossible');
    });
  });
}
