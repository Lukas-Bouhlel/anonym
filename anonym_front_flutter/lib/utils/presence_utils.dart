/// Utilitaires de gestion du statut de présence utilisateur.
class PresenceUtils {
  static const online = 'online';
  static const idle = 'idle';
  static const dnd = 'dnd';
  static const offline = 'offline';
  static const invisible = 'invisible';

  /// Normalise une valeur de statut vers une valeur supportée.
  static String normalize(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    switch (value) {
      case online:
      case idle:
      case dnd:
      case offline:
      case invisible:
        return value;
      default:
        return offline;
    }
  }

  /// Calcule le statut visible par un viewer.
  static String effectiveForViewer(String? raw, {required bool isCurrentUser}) {
    final normalized = normalize(raw);
    if (normalized == invisible && !isCurrentUser) return offline;
    return normalized;
  }

  /// Libellé localisé à afficher pour un statut de présence.
  static String label(String? raw, {required bool isCurrentUser}) {
    final value = effectiveForViewer(raw, isCurrentUser: isCurrentUser);
    switch (value) {
      case online:
        return 'En ligne';
      case idle:
        return 'Inactif';
      case dnd:
        return 'Ne pas deranger';
      case invisible:
        return 'Invisible';
      default:
        return 'Hors ligne';
    }
  }
}
