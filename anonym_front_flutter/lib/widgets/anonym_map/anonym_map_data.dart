/// Camera target used to focus [AnonymMapView] on a location.
///
/// {@tool snippet}
/// const AnonymMapCameraTarget(
///   latitude: 48.8566,
///   longitude: 2.3522,
///   zoom: 14,
///   revision: 2,
/// )
/// {@end-tool}
///
/// Error cases:
/// - Invalid coordinates (outside valid lat/lng ranges) are not validated here
///   and may be rejected by the underlying map SDK.
/// - [revision] must be increased when forcing a camera refresh in consumers.
class AnonymMapCameraTarget {
  const AnonymMapCameraTarget({
    required this.latitude,
    required this.longitude,
    required this.revision,
    this.zoom = 13.5,
  });

  final double latitude;
  final double longitude;
  final double zoom;
  final int revision;

  Map<String, Object> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'zoom': zoom,
      'revision': revision,
    };
  }
}
