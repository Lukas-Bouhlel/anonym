import 'package:flutter/material.dart';

import '../../models/live_user_location_model.dart';
import '../../theme.dart';
import 'anonym_map_data.dart';

/// Stub implementation shown when no supported map backend is available.
///
/// {@tool snippet}
/// const AnonymMapView(
///   locations: [],
///   selfUserId: null,
/// )
/// {@end-tool}
///
/// Error cases:
/// - This implementation is intentionally non-interactive and does not render
///   markers even when [locations] is not empty.
class AnonymMapView extends StatelessWidget {
  const AnonymMapView({
    super.key,
    required this.locations,
    required this.selfUserId,
    this.cameraTarget,
  });

  final List<LiveUserLocationModel> locations;
  final int? selfUserId;
  final AnonymMapCameraTarget? cameraTarget;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.c393566,
      child: Center(
        child: Text(
          'Carte indisponible sur cette plateforme.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.cFCFAFE,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
