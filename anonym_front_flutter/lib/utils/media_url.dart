import 'app_config.dart';

/// Normalise les URLs média renvoyées par l'API pour l'affichage client.
abstract final class MediaUrl {
  static const _localHosts = {
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '::1',
    '[::1]',
  };

  /// Retourne `null` pour les valeurs vides, sinon une URL normalisée.
  static String? nullable(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return normalize(value);
  }

  /// Convertit une URL relative/locale en URL exploitable côté client.
  static String normalize(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;

    if (value.startsWith('data:') || value.startsWith('blob:')) {
      return value;
    }

    final apiBase = Uri.parse(AppConfig.apiBaseUrl);
    final parsed = Uri.tryParse(value);

    if (parsed != null && parsed.hasScheme) {
      if (parsed.path.startsWith('/uploads/')) {
        return _rebase(parsed, apiBase);
      }
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
