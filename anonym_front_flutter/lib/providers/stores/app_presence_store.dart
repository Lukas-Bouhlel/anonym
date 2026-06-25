import '../../models/live_user_location_model.dart';

class AppPresenceStore {
  final Map<int, LiveUserLocationModel> liveLocationsByUserId = {};
  final Map<int, String> presenceByUserId = {};
}
