/// Cross-platform export for [AnonymMapView].
///
/// - Uses web implementation when `dart.library.html` is available.
/// - Uses IO implementation when `dart.library.io` is available.
/// - Falls back to a stub otherwise.
///
/// {@tool snippet}
/// import 'package:anonym_front_flutter/widgets/anonym_map/anonym_map_view.dart';
///
/// // Use AnonymMapView without caring about platform file selection.
/// {@end-tool}
library;

export 'anonym_map_view_stub.dart'
    if (dart.library.html) 'anonym_map_view_web.dart'
    if (dart.library.io) 'anonym_map_view_io.dart';
