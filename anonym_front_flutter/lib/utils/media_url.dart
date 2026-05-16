import 'app_config.dart';

class MediaUrl {
  const MediaUrl._();

  static const _localHosts = {
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '::1',
    '[::1]',
  };

  static String? nullable(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return normalize(value);
  }

  static String normalize(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;

    if (value.startsWith('data:') || value.startsWith('blob:')) {
      return value;
    }

    final apiBase = Uri.parse(AppConfig.apiBaseUrl);
    final parsed = Uri.tryParse(value);

    if (parsed != null && parsed.hasScheme) {
      if (_localHosts.contains(parsed.host.toLowerCase())) {
        return _rebase(parsed, apiBase);
      }
      return value;
    }

    final path = value.startsWith('/') ? value : '/$value';
    return apiBase.resolve(path).toString();
  }

  static String _rebase(Uri source, Uri base) {
    return base
        .replace(
          path: source.path,
          query: source.hasQuery ? source.query : null,
          fragment: source.hasFragment ? source.fragment : null,
        )
        .toString();
  }
}
