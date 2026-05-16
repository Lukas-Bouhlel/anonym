import 'package:flutter/material.dart';

import '../../models/live_user_location_model.dart';
import '../../theme.dart';
import 'moji_map_data.dart';

class MojiMapView extends StatelessWidget {
  const MojiMapView({
    super.key,
    required this.locations,
    required this.selfUserId,
    this.cameraTarget,
  });

  final List<LiveUserLocationModel> locations;
  final int? selfUserId;
  final MojiMapCameraTarget? cameraTarget;

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
