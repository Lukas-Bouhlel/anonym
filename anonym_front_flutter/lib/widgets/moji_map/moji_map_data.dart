class MojiMapCameraTarget {
  const MojiMapCameraTarget({
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
