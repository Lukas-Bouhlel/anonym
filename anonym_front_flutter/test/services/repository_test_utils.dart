import 'package:anonym_front_flutter/services/api_client.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockApiClient extends Mock implements ApiClient {}

Response<T> dioResponse<T>(
  T data, {
  String path = '/test',
  int statusCode = 200,
}) {
  return Response<T>(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: path),
  );
}

DioException dioException({
  required String path,
  int statusCode = 500,
  Object? data,
}) {
  return DioException(
    requestOptions: RequestOptions(path: path),
    response: Response<dynamic>(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: path),
    ),
    type: DioExceptionType.badResponse,
  );
}

