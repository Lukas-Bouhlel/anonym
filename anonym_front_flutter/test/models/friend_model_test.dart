import 'package:anonym_front_flutter/models/friend_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FriendModel', () {
    test('fromJson parses friend details from multiple aliases', () {
      final model = FriendModel.fromJson({
        'id': '10',
        'user_id': 1,
        'friend_id': '2',
        'status': 'PENDING',
        'sender': {
          'id': 2,
          'username': 'bob',
          'email': 'bob@test.dev',
        },
      });

      expect(model.id, 10);
      expect(model.userId, 1);
      expect(model.friendId, 2);
      expect(model.status, 'PENDING');
      expect(model.friendDetails?.username, 'bob');
    });

    test('fromJson applies defaults when values are invalid', () {
      final model = FriendModel.fromJson({
        'id': 'x',
        'userId': 'y',
        'friendId': 'z',
      });

      expect(model.id, 0);
      expect(model.userId, 0);
      expect(model.friendId, 0);
      expect(model.status, 'ACTIVE');
      expect(model.friendDetails, isNull);
    });
  });
}

