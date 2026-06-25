import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/home_location_controller.dart';
import '../models/live_user_location_model.dart';
import '../providers/app_orchestrator_provider.dart';
import '../providers/auth_providers.dart';
import '../providers/presence_provider.dart';
import '../theme.dart';
import '../utils/app_logger.dart';
import '../widgets/anonym_map/anonym_map_view.dart';

part '../widgets/home_screen_widgets.dart';

/// Écran d accueil principal avec carte et présence live.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _bottomNavVisualHeight = 80;
  static const double _bottomNavOuterSpacing = 40;
  static const double _mapControlsGapAboveToolbar = 34;

  final GlobalKey<_HomeMapState> _mapKey = GlobalKey<_HomeMapState>();

  Future<void> _recenterOnMyPosition() async {
    await _mapKey.currentState?.centerOnMyCurrentLocation();
  }

  double _mapControlsBottomOffset(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return safeBottom +
        _bottomNavVisualHeight +
        _bottomNavOuterSpacing +
        _mapControlsGapAboveToolbar;
  }

  @override
  Widget build(BuildContext context) {
    final username = context.select<AuthProvider, String?>(
      (auth) => auth.user?.username,
    );
    final errorMessage = context.select<AppOrchestratorProvider, String?>(
      (orchestrator) => orchestrator.errorMessage,
    );
    final orchestrator = context.read<AppOrchestratorProvider>();
    final t = Theme.of(context).textTheme;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _HomeMap(key: _mapKey)),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xAA393566),
                      Color(0x18393566),
                      Color(0x88393566),
                    ],
                    stops: [0, 0.42, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Text(
                  'Salut\n${username ?? 'Anonym'} !',
                  style: t.displayLarge?.copyWith(
                    height: 0.95,
                    shadows: const [
                      Shadow(
                        blurRadius: 18,
                        color: Color(0x99393566),
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: _mapControlsBottomOffset(context),
            child: _MapboxStyleControlGroup(
              onLocatePressed: () {
                unawaited(_recenterOnMyPosition());
              },
              onRefreshPressed: orchestrator.refreshAll,
            ),
          ),
          if (errorMessage != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: _mapControlsBottomOffset(context) + 92,
              child: _StatusMessage(message: errorMessage),
            ),
        ],
      ),
    );
  }
}
