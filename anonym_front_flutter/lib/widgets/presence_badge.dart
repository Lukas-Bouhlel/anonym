import 'package:flutter/material.dart';

import '../utils/presence_utils.dart';

/// Renders a circular presence indicator for a user.
///
/// Uses [PresenceUtils.effectiveForViewer] to map hidden/invisible states
/// depending on whether the viewer is the same user.
///
/// {@tool snippet}
/// PresenceBadge(
///   presenceStatus: friend.presenceStatus,
///   isCurrentUser: false,
///   size: 12,
/// )
/// {@end-tool}
///
/// Error cases:
/// - Unknown [presenceStatus] values fallback to an offline-like neutral color.
/// - Very small [size] values can make the border visually clipped.
class PresenceBadge extends StatelessWidget {
  const PresenceBadge({
    super.key,
    required this.presenceStatus,
    required this.isCurrentUser,
    this.size = 14,
    this.borderColor = Colors.white,
    this.borderWidth = 0.5,
  });

  final String? presenceStatus;
  final bool isCurrentUser;
  final double size;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final effective = PresenceUtils.effectiveForViewer(
      presenceStatus,
      isCurrentUser: isCurrentUser,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _statusColor(effective),
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case PresenceUtils.online:
        return const Color(0xFF97F6C1);
      case PresenceUtils.idle:
        return const Color(0xFFFFC857);
      case PresenceUtils.dnd:
        return const Color(0xFFFF6B6B);
      case PresenceUtils.invisible:
      case PresenceUtils.offline:
      default:
        return const Color(0xFF9AA4C1);
    }
  }
}
