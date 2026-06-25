import 'package:dio/dio.dart';

/// No-op on platforms without `dart:io` (notably Web).
void applyNetworkSecurity(Dio dio) {}
