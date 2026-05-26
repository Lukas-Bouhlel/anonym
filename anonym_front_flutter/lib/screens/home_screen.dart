import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:provider/provider.dart';

import '../models/live_user_location_model.dart';
import '../providers/app_providers.dart';
import '../providers/auth_providers.dart';
import '../theme.dart';
import '../widgets/anonym_map/anonym_map_data.dart';
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
    final user = context.watch<AuthProvider>().user;
    final t = Theme.of(context).textTheme;

    return Consumer<AppProvider>(
      builder: (context, app, _) {
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
                      'Salut\n${user?.username ?? 'Anonym'} !',
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
                  onRefreshPressed: app.refreshAll,
                ),
              ),
              if (app.errorMessage != null)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: _mapControlsBottomOffset(context) + 92,
                  child: _StatusMessage(message: app.errorMessage!),
                ),
            ],
          ),
        );
      },
    );
  }
}
