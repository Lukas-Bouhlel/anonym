import 'package:dio/dio.dart';

import '../models/friend_model.dart';
import '../models/user_model.dart';

/// Repository HTTP pour le graphe social (amis, demandes, blocages).
class FriendsRepository {
  FriendsRepository(this._dio);

  final Dio _dio;

  Future<List<FriendModel>> readAll() async {
    final response = await _dio.get<List<dynamic>>('/api/friends');
    final payload = response.data ?? const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(FriendModel.fromJson)
        .toList(growable: false);
  }

  Future<FriendModel> readById(int friendId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/friends/$friendId',
    );
    return FriendModel.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<FriendModel?> addByUsername(String username) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/friends/$username',
    );
    final payload = response.data;
    if (payload == null) return null;
    return FriendModel.fromJson(payload);
  }

  Future<void> updateStatus({
    required int friendId,
    required String status,
  }) async {
    await _dio.put<void>('/api/friends/$friendId', data: {'status': status});
  }

  Future<void> deleteById(int friendId) async {
    await _dio.delete<void>('/api/friends/$friendId');
  }

  Future<List<FriendModel>> readIncomingRequests() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/friends/requests/incoming',
    );
    final payload = response.data ?? const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(FriendModel.fromJson)
        .toList(growable: false);
  }

  Future<List<FriendModel>> readOutgoingRequests() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/friends/requests/outgoing',
    );
    final payload = response.data ?? const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map(FriendModel.fromJson)
        .toList(growable: false);
  }

  Future<void> respondToRequest({
    required int requestId,
    required String status,
  }) async {
    try {
      await _dio.put<void>(
        '/api/friends/requests/$requestId/respond',
        data: {'status': status},
      );
    } on DioException catch (e) {
      if (_isAlreadyHandledRequestError(e)) return;
      rethrow;
    }
  }

  Future<void> cancelOutgoingRequest(int requestId) async {
    try {
      await _dio.delete<void>('/api/friends/requests/$requestId');
    } on DioException catch (e) {
      if (_isAlreadyHandledRequestError(e)) return;
      rethrow;
    }
  }

  Future<List<UserModel>> readBlockedUsers() async {
    final response = await _dio.get<List<dynamic>>('/api/friends/blocked');
    final payload = response.data ?? const [];

    return payload
        .whereType<Map<String, dynamic>>()
        .map((json) {
          final details =
              json['FriendDetails'] ??
              json['friendDetails'] ??
              json['UserDetails'] ??
              json['userDetails'] ??
              json['user'] ??
              json['friend'] ??
              json;
          if (details is Map<String, dynamic>) {
            return UserModel.fromJson(details);
          }
          return const UserModel(id: 0, username: 'Utilisateur', email: '');
        })
        .toList(growable: false);
  }

  Future<void> blockUserById(int userId) async {
    await _dio.post<void>('/api/friends/$userId/block');
  }

  Future<void> unblockUserById(int userId) async {
    await _dio.delete<void>('/api/friends/$userId/block');
  }

  bool _isAlreadyHandledRequestError(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    if (statusCode != 404) return false;
    final payload = error.response?.data;
    final message = payload is Map<String, dynamic>
        ? (payload['message'] ?? '').toString().toLowerCase()
        : payload?.toString().toLowerCase() ?? '';
    return message.contains('not found') ||
        message.contains('introuvable') ||
        message.contains('friend request');
  }
}
