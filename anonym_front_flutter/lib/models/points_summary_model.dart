class PointsSummaryModel {
  const PointsSummaryModel({
    required this.period,
    required this.periodSelection,
    required this.range,
    required this.user,
    required this.totals,
    required this.history,
  });

  final String period;
  final String periodSelection;
  final PointsRangeModel range;
  final PointsUserModel user;
  final PointsTotalsModel totals;
  final List<PointsHistoryBucketModel> history;

  factory PointsSummaryModel.fromJson(Map<String, dynamic> json) {
    return PointsSummaryModel(
      period: (json['period'] ?? 'day').toString(),
      periodSelection: (json['periodSelection'] ?? 'auto').toString(),
      range: PointsRangeModel.fromJson(
        (json['range'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      user: PointsUserModel.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      totals: PointsTotalsModel.fromJson(
        (json['totals'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      history: ((json['history'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PointsHistoryBucketModel.fromJson)
          .toList(growable: false),
    );
  }
}

class PointsRangeModel {
  const PointsRangeModel({required this.startDate, required this.endDate});

  final DateTime? startDate;
  final DateTime? endDate;

  factory PointsRangeModel.fromJson(Map<String, dynamic> json) {
    return PointsRangeModel(
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
    );
  }
}

class PointsUserModel {
  const PointsUserModel({
    required this.id,
    required this.username,
    required this.totalPoints,
    required this.level,
  });

  final int id;
  final String username;
  final int totalPoints;
  final PointsLevelModel level;

  factory PointsUserModel.fromJson(Map<String, dynamic> json) {
    return PointsUserModel(
      id: _toInt(json['id']),
      username: (json['username'] ?? '').toString(),
      totalPoints: _toInt(json['totalPoints']),
      level: PointsLevelModel.fromJson(
        (json['level'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
    );
  }
}

class PointsLevelModel {
  const PointsLevelModel({
    required this.level,
    required this.maxLevel,
    required this.totalPoints,
    required this.currentLevelThreshold,
    required this.nextLevelThreshold,
    required this.pointsIntoLevel,
    required this.pointsNeededForNextLevel,
    required this.pointsRemainingForNextLevel,
    required this.isMaxLevel,
  });

  final int level;
  final int maxLevel;
  final int totalPoints;
  final int currentLevelThreshold;
  final int nextLevelThreshold;
  final int pointsIntoLevel;
  final int pointsNeededForNextLevel;
  final int pointsRemainingForNextLevel;
  final bool isMaxLevel;

  double get completionRatio {
    if (isMaxLevel) return 1;
    if (pointsNeededForNextLevel <= 0) return 0;
    return (pointsIntoLevel / pointsNeededForNextLevel).clamp(0, 1);
  }

  factory PointsLevelModel.fromJson(Map<String, dynamic> json) {
    return PointsLevelModel(
      level: _toInt(json['level']),
      maxLevel: _toInt(json['maxLevel']),
      totalPoints: _toInt(json['totalPoints']),
      currentLevelThreshold: _toInt(json['currentLevelThreshold']),
      nextLevelThreshold: _toInt(json['nextLevelThreshold']),
      pointsIntoLevel: _toInt(json['pointsIntoLevel']),
      pointsNeededForNextLevel: _toInt(json['pointsNeededForNextLevel']),
      pointsRemainingForNextLevel: _toInt(json['pointsRemainingForNextLevel']),
      isMaxLevel: json['isMaxLevel'] == true,
    );
  }
}

class PointsTotalsModel {
  const PointsTotalsModel({
    required this.messagesCount,
    required this.pointsEarned,
  });

  final int messagesCount;
  final int pointsEarned;

  factory PointsTotalsModel.fromJson(Map<String, dynamic> json) {
    return PointsTotalsModel(
      messagesCount: _toInt(json['messagesCount']),
      pointsEarned: _toInt(json['pointsEarned']),
    );
  }
}

class PointsHistoryBucketModel {
  const PointsHistoryBucketModel({
    required this.bucket,
    required this.messagesCount,
    required this.pointsEarned,
  });

  final DateTime? bucket;
  final int messagesCount;
  final int pointsEarned;

  factory PointsHistoryBucketModel.fromJson(Map<String, dynamic> json) {
    return PointsHistoryBucketModel(
      bucket: _parseDate(json['bucket']),
      messagesCount: _toInt(json['messagesCount']),
      pointsEarned: _toInt(json['pointsEarned']),
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
