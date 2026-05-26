import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/live_user_location_model.dart';
import '../../utils/media_url.dart';

/// Single member rendered inside a map marker (single user or cluster).
///
/// {@tool snippet}
/// final markerMember = AnonymMapMarkerMember(
///   userId: 42,
///   username: 'alice',
///   initials: 'A',
///   fallbackColor: const Color(0xFF393566),
/// );
/// {@end-tool}
///
/// Error cases:
/// - [initials] is trusted as-is; pass a non-empty value for consistent UI.
class AnonymMapMarkerMember {
  const AnonymMapMarkerMember({
    required this.userId,
    required this.username,
    required this.initials,
    required this.fallbackColor,
    this.avatarUrl,
    this.frameUrl,
  });

  final int userId;
  final String username;
  final String initials;
  final Color fallbackColor;
  final String? avatarUrl;
  final String? frameUrl;

  Map<String, Object?> toJson() {
    return {
      'userId': userId,
      'username': username,
      'initials': initials,
      'fallbackColor': _cssColor(fallbackColor),
      'avatarUrl': avatarUrl,
      'frameUrl': frameUrl,
    };
  }
}

/// Marker payload used by native/web map implementations.
///
/// {@tool snippet}
/// final marker = AnonymMapMarkerData(
///   key: 'u:42',
///   latitude: 48.8566,
///   longitude: 2.3522,
///   label: 'alice',
///   members: const [],
/// );
/// {@end-tool}
///
/// Error cases:
/// - Empty [members] is allowed but usually indicates upstream data issues.
class AnonymMapMarkerData {
  const AnonymMapMarkerData({
    required this.key,
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.members,
  });

  final String key;
  final double latitude;
  final double longitude;
  final String label;
  final List<AnonymMapMarkerMember> members;

  Map<String, Object?> toJson() {
    return {
      'key': key,
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
      'members': members.map((member) => member.toJson()).toList(),
    };
  }
}

/// Builds clustered marker data from realtime locations.
///
/// {@tool snippet}
/// final markers = buildAnonymMapMarkers(locations, authUserId);
/// {@end-tool}
///
/// Error cases:
/// - Empty [locations] returns an empty list.
/// - Invalid coordinates are forwarded and may fail later in map SDKs.
List<AnonymMapMarkerData> buildAnonymMapMarkers(
  List<LiveUserLocationModel> locations,
  int? selfUserId,
) {
  final clusters = _buildClusters(locations);
  return [
    for (final cluster in clusters) _markerForCluster(cluster, selfUserId),
  ];
}

/// Computes a stable lightweight fingerprint for marker change detection.
///
/// {@tool snippet}
/// final fingerprint = anonymMapMarkerFingerprint(markers);
/// {@end-tool}
String anonymMapMarkerFingerprint(List<AnonymMapMarkerData> markers) {
  final buffer = StringBuffer();
  for (final marker in markers) {
    buffer
      ..write(marker.key)
      ..write('|');
  }
  return buffer.toString();
}

AnonymMapMarkerData _markerForCluster(_LocationCluster cluster, int? selfUserId) {
  final sortedMembers = [...cluster.members]
    ..sort((a, b) => a.userId.compareTo(b.userId));
  final members = [
    for (final member in sortedMembers)
      AnonymMapMarkerMember(
        userId: member.userId,
        username: member.username,
        initials: _initialsFor(member.username),
        fallbackColor: anonymMapColorForUser(member.userId),
        avatarUrl: MediaUrl.nullable(member.avatar),
        frameUrl: MediaUrl.nullable(member.frameUrl),
      ),
  ];

  final label = _buildClusterLabel(sortedMembers, selfUserId);
  final keyBuffer = StringBuffer('self:${selfUserId ?? 0}|');
  for (final item in sortedMembers) {
    keyBuffer
      ..write(item.userId)
      ..write(':')
      ..write(item.latitude.toStringAsFixed(5))
      ..write(':')
      ..write(item.longitude.toStringAsFixed(5))
      ..write(':')
      ..write(item.username)
      ..write(':')
      ..write(MediaUrl.nullable(item.avatar) ?? '')
      ..write(':')
      ..write(MediaUrl.nullable(item.frameUrl) ?? '')
      ..write('|');
  }

  return AnonymMapMarkerData(
    key: keyBuffer.toString(),
    latitude: cluster.latitude,
    longitude: cluster.longitude,
    label: label,
    members: members,
  );
}

/// Returns a deterministic fallback color for a user id.
///
/// {@tool snippet}
/// final color = anonymMapColorForUser(user.id);
/// {@end-tool}
Color anonymMapColorForUser(int userId) {
  const palette = <Color>[
    Color(0xFF393566),
    Color(0xFF8E97F8),
    Color(0xFF212121),
    Color(0xFF6F35FF),
    Color(0xFF4A9FD1),
    Color(0xFFE24D6B),
  ];
  return palette[userId.abs() % palette.length];
}

String _buildClusterLabel(
  List<LiveUserLocationModel> members,
  int? selfUserId,
) {
  final names = members
      .map((member) => member.userId == selfUserId ? 'Moi' : member.username)
      .toList(growable: false);

  if (names.length == 1) return names.first;
  if (names.length == 2) return '${names[0]} & ${names[1]}';
  if (names.length == 3) return '${names[0]}, ${names[1]} & ${names[2]}';
  return '${names[0]}, ${names[1]}...';
}

List<_LocationCluster> _buildClusters(List<LiveUserLocationModel> locations) {
  const mergeDistanceMeters = 150.0;
  final clusters = <_LocationCluster>[];

  for (final location in locations) {
    _LocationCluster? target;
    for (final cluster in clusters) {
      final distance = _distanceInMeters(
        location.latitude,
        location.longitude,
        cluster.latitude,
        cluster.longitude,
      );
      if (distance <= mergeDistanceMeters) {
        target = cluster;
        break;
      }
    }

    if (target == null) {
      clusters.add(_LocationCluster.from(location));
    } else {
      target.add(location);
    }
  }
  return clusters;
}

String _initialsFor(String username) {
  final trimmed = username.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

String _cssColor(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}

double _distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a =
      (sin(dLat / 2) * sin(dLat / 2)) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          (sin(dLon / 2) * sin(dLon / 2));
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusMeters * c;
}

double _toRadians(double deg) => deg * 0.017453292519943295;

class _LocationCluster {
  _LocationCluster.from(LiveUserLocationModel first)
    : members = <LiveUserLocationModel>[first],
      latitude = first.latitude,
      longitude = first.longitude;

  final List<LiveUserLocationModel> members;
  double latitude;
  double longitude;

  void add(LiveUserLocationModel next) {
    members.add(next);
    final count = members.length;
    latitude = ((latitude * (count - 1)) + next.latitude) / count;
    longitude = ((longitude * (count - 1)) + next.longitude) / count;
  }
}
