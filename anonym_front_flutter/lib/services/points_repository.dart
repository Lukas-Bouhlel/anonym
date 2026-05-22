import 'package:dio/dio.dart';

import '../models/points_summary_model.dart';

class PointsRepository {
  PointsRepository(this._dio);

  final Dio _dio;

  Future<PointsSummaryModel> readMe({
    String? period,
    DateTime? startDate,
  }) async {
    final query = <String, dynamic>{};
    if (period != null && period.trim().isNotEmpty) {
      query['period'] = period;
    }
    if (startDate != null) {
      query['startDate'] = _formatDate(startDate);
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/api/points/me',
      queryParameters: query,
    );

    return PointsSummaryModel.fromJson(response.data ?? <String, dynamic>{});
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
