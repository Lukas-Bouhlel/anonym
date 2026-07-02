import 'package:anonym_front_flutter/services/api_client.dart';
import 'package:anonym_front_flutter/utils/app_config.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiClient', () {
    test('buildSocketAuthHeaders only exposes token cookie', () async {
      final jar = CookieJar();
      final uri = Uri.parse(AppConfig.apiBaseUrl);
      await jar.saveFromResponse(uri, <Cookie>[
        Cookie('token', 'abc123'),
        Cookie('csrfToken', 'csrf-value'),
      ]);

      final client = ApiClient(cookieJar: jar);
      final headers = await client.buildSocketAuthHeaders();

      expect(headers, isNotEmpty);
      expect(headers['Cookie'], 'token=abc123');
    });

    test(
      'buildSocketAuthHeaders returns empty when token cookie is missing',
      () async {
        final jar = CookieJar();
        final uri = Uri.parse(AppConfig.apiBaseUrl);
        await jar.saveFromResponse(uri, <Cookie>[
          Cookie('csrfToken', 'csrf-value'),
          Cookie('refreshToken', 'refresh-value'),
        ]);

        final client = ApiClient(cookieJar: jar);
        final headers = await client.buildSocketAuthHeaders();

        expect(headers, isEmpty);
      },
    );

    test('hasStoredAuthSession accepts refresh-only session', () async {
      final jar = CookieJar();
      final uri = Uri.parse(AppConfig.apiBaseUrl);
      await jar.saveFromResponse(uri, <Cookie>[
        Cookie('refreshToken', 'refresh-value'),
      ]);

      final client = ApiClient(cookieJar: jar);

      expect(await client.hasStoredAuthSession(), isTrue);
    });

    test(
      'buildSocketAuthToken reads token cookie and returns null when missing',
      () async {
        final uri = Uri.parse(AppConfig.apiBaseUrl);

        final jarWithToken = CookieJar();
        await jarWithToken.saveFromResponse(uri, <Cookie>[
          Cookie('token', 'tok'),
        ]);
        final clientWithToken = ApiClient(cookieJar: jarWithToken);
        expect(await clientWithToken.buildSocketAuthToken(), 'tok');

        final jarWithoutToken = CookieJar();
        await jarWithoutToken.saveFromResponse(uri, <Cookie>[
          Cookie('csrfToken', 'x'),
        ]);
        final clientWithoutToken = ApiClient(cookieJar: jarWithoutToken);
        expect(await clientWithoutToken.buildSocketAuthToken(), isNull);
      },
    );

    test(
      'clearSessionData removes stored cookies used by socket auth helpers',
      () async {
        final jar = CookieJar();
        final uri = Uri.parse(AppConfig.apiBaseUrl);
        await jar.saveFromResponse(uri, <Cookie>[Cookie('token', 'abc')]);

        final client = ApiClient(cookieJar: jar);
        expect(await client.buildSocketAuthHeaders(), isNotEmpty);

        await client.clearSessionData();

        expect(await client.buildSocketAuthHeaders(), isEmpty);
        expect(await client.buildSocketAuthToken(), isNull);
      },
    );
  });
}
