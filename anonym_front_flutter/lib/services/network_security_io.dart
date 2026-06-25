import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../utils/app_config.dart';

/// Applies native TLS certificate pinning when configured.
///
/// Pin format: SHA-256 fingerprint of the leaf certificate in lowercase hex
/// without separators.
void applyNetworkSecurity(Dio dio) {
  if (!AppConfig.isTlsPinningEnabled) {
    return;
  }

  final pins = AppConfig.tlsPinnedCertSha256;
  if (pins.isEmpty) {
    throw StateError(
      'TLS pinning is enabled but no certificate pins are configured. '
      'Set TLS_PINNED_CERT_SHA256 with one or more SHA-256 fingerprints.',
    );
  }

  final baseUri = Uri.tryParse(dio.options.baseUrl);
  final expectedHost = baseUri?.host.trim().toLowerCase();

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => HttpClient(),
    validateCertificate: (certificate, host, port) {
      if (certificate == null) {
        return false;
      }
      if (expectedHost != null &&
          expectedHost.isNotEmpty &&
          host.trim().toLowerCase() != expectedHost) {
        return false;
      }
      final fingerprint = sha256.convert(certificate.der).toString();
      return pins.contains(fingerprint);
    },
  );
}
