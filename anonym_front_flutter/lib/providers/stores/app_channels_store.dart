import '../../models/channel_message_model.dart';
import '../../models/channel_model.dart';
import '../../models/user_model.dart';

class AppChannelsStore {
  List<ChannelModel> channels = const [];
  List<ChannelModel> publicChannels = const [];
  ChannelModel? selectedChannel;
  List<UserModel> channelMembers = const [];
  List<ChannelMessageModel> messages = const [];
  String lastPublicChannelsFilter = 'all';
}
