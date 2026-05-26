import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/live_user_location_model.dart';
import '../../utils/media_url.dart';

class MojiMapMarkerMember {
  const MojiMapMarkerMember({
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

class MojiMapMarkerData {
  const MojiMapMarkerData({
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
  final List<MojiMapMarkerMember> members;

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

List<MojiMapMarkerData> buildMojiMapMarkers(
  List<LiveUserLocationModel> locations,
  int? selfUserId,
) {
  final clusters = _buildClusters(locations);
  return [
    for (final cluster in clusters) _markerForCluster(cluster, selfUserId),
  ];
}

String mojiMapMarkerFingerprint(List<MojiMapMarkerData> markers) {
  final buffer = StringBuffer();
  for (final marker in markers) {
    buffer
      ..write(marker.key)
      ..write('|');
  }
  return buffer.toString();
}

MojiMapMarkerData _markerForCluster(_LocationCluster cluster, int? selfUserId) {
  final sortedMembers = [...cluster.members]
    ..sort((a, b) => a.userId.compareTo(b.userId));
  final members = [
    for (final member in sortedMembers)
      MojiMapMarkerMember(
        userId: member.userId,
        username: member.username,
        initials: _initialsFor(member.username),
        fallbackColor: mojiMapColorForUser(member.userId),
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

  return MojiMapMarkerData(
    key: keyBuffer.toString(),
    latitude: cluster.latitude,
    longitude: cluster.longitude,
    label: label,
    members: members,
  );
}

Color mojiMapColorForUser(int userId) {
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
