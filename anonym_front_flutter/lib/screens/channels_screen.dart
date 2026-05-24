import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/channel_message_model.dart';
import '../models/channel_model.dart';
import '../models/user_model.dart';
import '../providers/app_controller.dart';
import '../providers/auth_controller.dart';
import 'group_settings_screen.dart';
import 'user_profile_screen.dart';
import '../theme.dart';
import '../utils/app_date_format.dart';
import '../utils/presence_utils.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/chrome/moji_back_button.dart';
import '../widgets/modals/moji_confirm_modal.dart';
import '../widgets/presence_badge.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:image_picker/image_picker.dart';

part 'channels_parts/channel_sheet_widgets.dart';
part 'channels_parts/channel_list_widgets.dart';
part 'channels_parts/channel_chat_widgets.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  ChannelMessageModel? _editingMessage;
  String _query = '';
  String? _lastShownMessageError;

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthController>().user;
    final t = Theme.of(context).textTheme;

    return Consumer<AppController>(
      builder: (context, app, _) {
        final socketError = app.messageError;
        if (socketError == null) {
          _lastShownMessageError = null;
        }
        if (socketError != null &&
            socketError.isNotEmpty &&
            socketError != _lastShownMessageError) {
          _lastShownMessageError = socketError;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(socketError)));
            context.read<AppController>().clearMessageError();
          });
        }

        if (app.selectedChannel != null) {
          final selected = app.selectedChannel!;
          final isGroup = selected.channelType.trim().toUpperCase() == 'GROUP';
          final isDm =
              selected.channelType.trim().toUpperCase() == 'PRIVATE_DM';
          final dmPeerFromMembers = isDm
              ? app.channelMembers.firstWhere(
                  (member) => member.id != currentUser?.id,
                  orElse: () => const UserModel(id: 0, username: '', email: ''),
                )
              : null;
          final hasMemberPeer = (dmPeerFromMembers?.username ?? '')
              .trim()
              .isNotEmpty;
          final dmPeer = hasMemberPeer ? dmPeerFromMembers : selected.dmPeer;
          final dmPeerName = (dmPeer?.username ?? '').trim();
          final hasDmPeerName = dmPeerName.isNotEmpty;
          return _ChatDetailView(
            currentUserId: currentUser?.id,
            currentUserName: currentUser?.username,
            currentUserAvatarUrl: currentUser?.avatar,
            currentUserFrameUrl: _activeFrameUrlFromUser(currentUser),
            isDm: isDm,
            dmPeerName: hasDmPeerName ? dmPeerName : null,
            dmPeerAvatarUrl: dmPeer?.avatar,
            dmPeerPresenceStatus: isDm && dmPeer != null
                ? app.presenceStatusForUser(dmPeer.id)
                : null,
            dmPeerPresenceLabel: isDm && dmPeer != null
                ? app.presenceLabelForUser(dmPeer.id)
                : null,
            onDmHeaderTap: isDm && dmPeer != null && dmPeer.id > 0
                ? () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      builder: (_) => FractionallySizedBox(
                        heightFactor: 0.86,
                        child: UserProfileScreen(user: dmPeer),
                      ),
                    );
                  }
                : null,
            messageController: _messageController,
            editingMessage: _editingMessage,
            onCancelEdit: _cancelEdit,
            onBack: app.closeSelectedChannelView,
            onSendText: () => _sendText(app),
            onSendImage: (path, bytes, fileName, text) =>
                _sendImage(app, path, bytes, fileName, text),
            onInfo: () => _showChannelInfoSheet(context, app),
            onEdit: (message) => _editMessage(context, app, message),
            onDelete: (message) =>
                _deleteMessage(context, app, message.messageId),
            selected: selected,
            messages: app.messages,
            loading: app.isLoadingMessages,
            showGroupMenu: isGroup,
          );
        }

        final channels = app.channels
            .where((channel) {
              final dmPeerName = channel.dmPeer?.username ?? '';
              final source =
                  '${channel.name} ${channel.description ?? ''} $dmPeerName'
                      .toLowerCase();
              return _query.isEmpty || source.contains(_query);
            })
            .toList(growable: false);

        return RefreshIndicator(
          onRefresh: () => app.refreshChannels(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 140),
            children: [
              SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Conversations', style: t.displayLarge),
                    ),
                    _HeaderIcon(
                      icon: Icons.add_rounded,
                      onTap: () => _showConversationActions(context, app),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 11.45),
                decoration: BoxDecoration(
                  gradient: AppGradients.gB1BCFBTo393566,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AppColors.whiteColor,
                      size: 27,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {
                          _query = value.trim().toLowerCase();
                        }),
                        style: const TextStyle(
                          color: AppColors.whiteColor,
                          fontFamily: AppTypography.primaryFontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        cursorColor: AppColors.whiteColor,
                        decoration: InputDecoration(
                          hintText: 'Chercher une conversation',
                          hintStyle: const TextStyle(
                            color: AppColors.whiteColor,
                            fontFamily: AppTypography.primaryFontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (channels.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aucune conversation.',
                    style: TextStyle(color: AppColors.cDBE7FE),
                  ),
                )
              else
                ...channels.map(
                  (channel) => _ConversationTile(
                    channel: channel,
                    dmPresenceStatus:
                        channel.channelType.trim().toUpperCase() ==
                                'PRIVATE_DM' &&
                            channel.dmPeer != null
                        ? app.presenceStatusForUser(channel.dmPeer!.id)
                        : null,
                    dmPresenceLabel:
                        channel.channelType.trim().toUpperCase() ==
                                'PRIVATE_DM' &&
                            channel.dmPeer != null
                        ? app.presenceLabelForUser(channel.dmPeer!.id)
                        : null,
                    onTap: () => app.selectChannel(channel),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _sendText(AppController app) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    app.clearMessageError();
    if (_editingMessage != null) {
      app.updateMessage(messageId: _editingMessage!.messageId, content: text);
      _cancelEdit();
    } else {
      app.sendMessage(text);
      _messageController.clear();
    }
  }

  Future<void> _sendImage(
    AppController app,
    String? filePath,
    Uint8List? bytes,
    String? fileName,
    String textContent,
  ) async {
    app.clearMessageError();
    await app.sendMessageWithImage(
      imagePath: filePath,
      imageBytes: bytes,
      imageFileName: fileName,
      content: textContent,
    );
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _messageController.clear();
    });
  }

  Future<void> _showConversationActions(
    BuildContext context,
    AppController app,
  ) async {
    final parentContext = context;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          decoration: BoxDecoration(
            gradient: AppGradients.gB1BCFBTo393566,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.3)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.login_rounded,
                  label: 'Rejoindre une conversation',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _openJoinPublicDirectoryScreen(parentContext, app);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openJoinPublicDirectoryScreen(
    BuildContext context,
    AppController app,
  ) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const _PublicConversationsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offset =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return SlideTransition(position: offset, child: child);
        },
      ),
    );
  }

  String? _activeFrameUrlFromUser(UserModel? user) {
    if (user == null) return null;
    for (final item in user.inventories) {
      if (!item.active) continue;
      final shop = item.shop;
      if (shop == null) continue;
      if (shop.type.trim().toUpperCase() != 'CADRE') continue;
      final content = shop.content.trim();
      if (content.isNotEmpty) return content;
    }
    return null;
  }

  Future<void> _deleteMessage(
    BuildContext context,
    AppController app,
    int messageId,
  ) async {
    await app.deleteMessage(messageId);
    if (!context.mounted) return;
    if (app.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(app.errorMessage!)));
    }
  }

  Future<void> _editMessage(
    BuildContext context,
    AppController app,
    ChannelMessageModel message,
  ) async {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.content;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    });
  }

  Future<void> _showChannelInfoSheet(
    BuildContext context,
    AppController app,
  ) async {
    final selected = app.selectedChannel;
    if (selected == null) return;
    final isPrivateDm =
        selected.channelType.trim().toUpperCase() == 'PRIVATE_DM';
    if (isPrivateDm) return;
    final currentUserId = context.read<AuthController>().user?.id;
    final isCreator =
        currentUserId != null && selected.createdBy == currentUserId;
    bool muted = false;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final bottomSafe = MediaQuery.of(context).padding.bottom;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 16 + bottomSafe),
              decoration: BoxDecoration(
                gradient: AppGradients.gB1BCFBTo393566,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: AppColors.cFCFAFE.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cFCFAFE.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selected.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFontFamily,
                            color: AppColors.cFCFAFE,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _InfoChip(label: selected.visibility.toUpperCase()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isCreator) ...[
                    _InfoRow(
                      icon: Icons.edit_rounded,
                      label: 'Modifier le groupe',
                      onTap: () async {
                        Navigator.of(context).pop();
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                GroupSettingsScreen(channel: selected),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  _InfoRow(
                    icon: Icons.group_outlined,
                    label: 'Voir les membres du groupe',
                    onTap: () async {
                      Navigator.of(context).pop();
                      if (!context.mounted) return;
                      await _showMembersSheet(context, app, selected);
                    },
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.link_rounded,
                    label: 'Creer une invitation',
                    onTap: () async {
                      Navigator.of(context).pop();
                      if (!context.mounted) return;
                      await _showInviteSheet(context, app, selected);
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppGradients.gB1BCFBTo393566,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.cFCFAFE.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cFCFAFE.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Icon(
                            muted
                                ? Icons.notifications_off_rounded
                                : Icons.notifications_active_rounded,
                            size: 18,
                            color: AppColors.cFCFAFE,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mettre en sourdine',
                                style: TextStyle(
                                  color: AppColors.cFCFAFE,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Notifications locales du groupe',
                                style: TextStyle(
                                  color: AppColors.cDBE7FE,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: muted,
                          activeThumbColor: AppColors.c393566,
                          activeTrackColor: AppColors.cCFFFDD,
                          inactiveThumbColor: AppColors.cFCFAFE,
                          inactiveTrackColor: AppColors.cFCFAFE.withValues(
                            alpha: 0.25,
                          ),
                          trackOutlineColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            return AppColors.cFCFAFE.withValues(alpha: 0.25);
                          }),
                          trackOutlineWidth: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            return 1.0;
                          }),
                          onChanged: (value) => setState(() => muted = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showMembersSheet(
    BuildContext context,
    AppController app,
    ChannelModel channel,
  ) async {
    await app.selectChannel(channel);
    if (!context.mounted) return;
    final currentUserId = context.read<AuthController>().user?.id;
    final isHost = currentUserId != null && channel.createdBy == currentUserId;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<AppController>(
          builder: (context, sheetApp, _) {
            final members = sheetApp.channelMembers;
            final bottomSafe = MediaQuery.of(context).padding.bottom;
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              padding: EdgeInsets.fromLTRB(14, 10, 14, 16 + bottomSafe),
              decoration: BoxDecoration(
                gradient: AppGradients.gB1BCFBTo393566,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: AppColors.cFCFAFE.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cFCFAFE.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const Text(
                    'Membres du groupe',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      color: AppColors.cFCFAFE,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: members.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: AppColors.cFCFAFE.withValues(alpha: 0.18),
                      ),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final canExclude =
                            isHost &&
                            member.id != channel.createdBy &&
                            member.id != currentUserId;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 1,
                          ),
                          leading: _MemberAvatar(member: member),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              builder: (_) => FractionallySizedBox(
                                heightFactor: 0.86,
                                child: UserProfileScreen(user: member),
                              ),
                            );
                          },
                          title: Text(
                            member.username.isNotEmpty
                                ? member.username
                                : 'User #${member.id}',
                            style: const TextStyle(color: AppColors.cFCFAFE),
                          ),
                          trailing: canExclude
                              ? IconButton(
                                  tooltip: 'Exclure du groupe',
                                  icon: const Icon(
                                    Icons.person_remove_rounded,
                                    color: AppColors.cFF6565,
                                  ),
                                  onPressed: () async {
                                    final shouldRemove =
                                        await _confirmMemberExclusion(
                                          context,
                                          member,
                                        );
                                    if (!shouldRemove) return;
                                    await sheetApp
                                        .removeMemberFromSelectedChannel(
                                          member.id,
                                        );
                                    if (!context.mounted) return;
                                    if (sheetApp.errorMessage != null &&
                                        sheetApp.errorMessage!.isNotEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(sheetApp.errorMessage!),
                                        ),
                                      );
                                    }
                                  },
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmMemberExclusion(
    BuildContext context,
    UserModel member,
  ) async {
    final username = member.username.trim().isEmpty
        ? 'cet utilisateur'
        : member.username.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => MojiConfirmModal(
        title: 'Exclure $username ?',
        description: 'Cette action retire immediatement ce membre du groupe.',
        confirmLabel: 'Exclure',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return confirmed == true;
  }

  Future<void> _showInviteSheet(
    BuildContext context,
    AppController app,
    ChannelModel channel,
  ) async {
    await app.selectChannel(channel);
    if (!context.mounted) return;

    var query = '';
    final invitedUserIds = <int>{};
    String? inviteLink;
    bool isGeneratingLink = false;
    bool didRequestInitialLink = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!didRequestInitialLink) {
              didRequestInitialLink = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted) return;
                setModalState(() => isGeneratingLink = true);
                final payload = await app.createInviteLinkForSelectedChannel(
                  mode: 'PERMANENT',
                );
                if (!context.mounted) return;
                final code = (payload?['code'] ?? '').toString().trim();
                final apiLink =
                    (payload?['link'] ??
                            payload?['url'] ??
                            payload?['inviteLink'])
                        ?.toString()
                        .trim();
                setModalState(() {
                  if (apiLink != null && apiLink.isNotEmpty) {
                    inviteLink = apiLink;
                  } else if (code.isNotEmpty) {
                    inviteLink = 'https://anonym.app/invite/$code';
                  } else {
                    inviteLink = null;
                  }
                  isGeneratingLink = false;
                });
                if (payload == null || inviteLink == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        app.errorMessage ??
                            'Creation du lien d invitation impossible',
                      ),
                    ),
                  );
                }
              });
            }

            final bottomSafe = MediaQuery.of(context).padding.bottom;
            final eligibleFriends = app.availableFriendsForSelectedChannel
                .where((friend) {
                  final user = friend.friendDetails;
                  if (user == null) return false;
                  final haystack = '${user.username} ${user.email}'
                      .toLowerCase();
                  return query.isEmpty || haystack.contains(query);
                })
                .toList(growable: false);

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              padding: EdgeInsets.fromLTRB(14, 10, 14, 16 + bottomSafe),
              decoration: BoxDecoration(
                gradient: AppGradients.gB1BCFBTo393566,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: AppColors.cFCFAFE.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    Text(
                      'Inviter des amis sur ${channel.name}',
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        color: AppColors.cFCFAFE,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppGradients.gB1BCFBTo393566,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.20),
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setModalState(
                            () => query = value.trim().toLowerCase(),
                          );
                        },
                        style: const TextStyle(color: AppColors.cFCFAFE),
                        decoration: InputDecoration(
                          hintText: 'Rechercher des amis',
                          hintStyle: TextStyle(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.55),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.cFCFAFE,
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: eligibleFriends.isEmpty
                          ? Center(
                              child: Text(
                                'Aucun ami a inviter',
                                style: TextStyle(
                                  color: AppColors.cFCFAFE.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: eligibleFriends.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 1,
                                color: AppColors.cFCFAFE.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                              itemBuilder: (context, index) {
                                final friend = eligibleFriends[index];
                                final user = friend.friendDetails!;
                                final invited = invitedUserIds.contains(
                                  user.id,
                                );
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.cFCFAFE
                                        .withValues(alpha: 0.12),
                                    child: AppRemoteImage(
                                      url: user.avatar,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      fallbackIcon: Icons.person_outline,
                                    ),
                                  ),
                                  title: Text(
                                    user.username.isNotEmpty
                                        ? user.username
                                        : 'User #${user.id}',
                                    style: const TextStyle(
                                      color: AppColors.cFCFAFE,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: user.email.trim().isEmpty
                                      ? null
                                      : Text(
                                          user.email,
                                          style: const TextStyle(
                                            color: AppColors.cDBE7FE,
                                          ),
                                        ),
                                  trailing: SizedBox(
                                    width: 110,
                                    height: 42,
                                    child: TextButton(
                                      onPressed: invited
                                          ? null
                                          : () async {
                                              await app
                                                  .inviteUsersToSelectedChannel(
                                                    [user.id],
                                                  );
                                              if (!context.mounted) return;
                                              final error = app.errorMessage;
                                              if (error != null &&
                                                  error.isNotEmpty) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(error),
                                                  ),
                                                );
                                                return;
                                              }
                                              setModalState(() {
                                                invitedUserIds.add(user.id);
                                              });
                                            },
                                      style: TextButton.styleFrom(
                                        backgroundColor: invited
                                            ? AppColors.cFCFAFE.withValues(
                                                alpha: 0.18,
                                              )
                                            : AppColors.cFCFAFE.withValues(
                                                alpha: 0.10,
                                              ),
                                        side: BorderSide(
                                          color: AppColors.cFCFAFE.withValues(
                                            alpha: 0.30,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        invited ? 'Invite' : 'Inviter',
                                        style: const TextStyle(
                                          color: AppColors.cFCFAFE,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Ou envoyer un lien d'invitation a un ami",
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        color: AppColors.cFCFAFE,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 62,
                      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                      decoration: BoxDecoration(
                        gradient: AppGradients.gB1BCFBTo393566,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.cFCFAFE.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isGeneratingLink
                                  ? 'Generation du lien...'
                                  : (inviteLink ?? 'Lien indisponible'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.cFCFAFE.withValues(
                                  alpha: inviteLink == null ? 0.65 : 1,
                                ),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 46,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: inviteLink == null || isGeneratingLink
                                    ? null
                                    : AppGradients.gB1BCFBTo393566,
                                color: inviteLink == null || isGeneratingLink
                                    ? AppColors.cFCFAFE.withValues(alpha: 0.12)
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextButton(
                                onPressed:
                                    inviteLink == null || isGeneratingLink
                                    ? null
                                    : () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: inviteLink!),
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Lien d invitation copie.',
                                            ),
                                          ),
                                        );
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.whiteColor,
                                  disabledForegroundColor: AppColors.cFCFAFE
                                      .withValues(alpha: 0.50),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isGeneratingLink
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.cFCFAFE,
                                        ),
                                      )
                                    : const Text(
                                        'Copier',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.whiteColor,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PublicConversationsScreen extends StatefulWidget {
  const _PublicConversationsScreen();

  @override
  State<_PublicConversationsScreen> createState() =>
      _PublicConversationsScreenState();
}

class _PublicConversationsScreenState extends State<_PublicConversationsScreen>
    with WidgetsBindingObserver {
  String _query = '';
  String _filter = 'all';
  final Map<String, int> _countsByFilter = {
    'all': 0,
    'joined': 0,
    'discover': 0,
  };
  bool _isSwitchingFilter = false;
  bool _isRealtimeRefreshing = false;
  int _filterRequestVersion = 0;
  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = context.read<AppController>();
      setState(() {
        _countsByFilter[_filter] = app.publicChannels.length;
      });
      _loadFilter(app, _filter, showLoader: true);
      _startRealtimeRefresh();
    });
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _refreshRealtime();
  }

  void _startRealtimeRefresh() {
    _realtimeTimer?.cancel();
    _realtimeTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _refreshRealtime();
    });
  }

  Future<void> _refreshCountsForAll(AppController app) async {
    try {
      final responses = await Future.wait([
        app.loadJoinDirectoryChannels(filter: 'all'),
        app.loadJoinDirectoryChannels(filter: 'joined'),
        app.loadJoinDirectoryChannels(filter: 'discover'),
      ]);
      if (!mounted) return;
      setState(() {
        _countsByFilter['all'] = responses[0].length;
        _countsByFilter['joined'] = responses[1].length;
        _countsByFilter['discover'] = responses[2].length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _countsByFilter[_filter] = app.publicChannels.length;
      });
    }
  }

  Future<void> _refreshRealtime() async {
    if (!mounted || _isRealtimeRefreshing || _isSwitchingFilter) return;
    _isRealtimeRefreshing = true;
    final app = context.read<AppController>();
    final activeFilter = _filter;
    try {
      await Future.wait([
        app.refreshChannels(silent: true),
        app.refreshPublicChannels(filter: activeFilter, silent: true),
      ]);
      if (!mounted) return;
      setState(() {
        _countsByFilter[activeFilter] = app.publicChannels.length;
      });
    } finally {
      _isRealtimeRefreshing = false;
    }
  }

  Future<void> _loadFilter(
    AppController app,
    String filter, {
    bool showLoader = false,
  }) async {
    final requestVersion = ++_filterRequestVersion;
    if (showLoader) {
      setState(() => _isSwitchingFilter = true);
    }
    await app.refreshPublicChannels(filter: filter, silent: true);
    if (!mounted || requestVersion != _filterRequestVersion) return;
    setState(() {
      _countsByFilter[filter] = app.publicChannels.length;
      _isSwitchingFilter = false;
    });
    unawaited(_refreshCountsForAll(app));
  }

  bool _isPublicGroupChannel(ChannelModel channel) {
    final type = channel.channelType.trim().toUpperCase();
    final visibility = channel.visibility.trim().toUpperCase();
    return type == 'GROUP' && visibility == 'PUBLIC';
  }

  Future<void> _handleJoinChannelTap(
    BuildContext context,
    AppController app,
    ChannelModel channel,
    bool joined,
  ) async {
    if (joined) {
      await app.selectChannel(channel);
    } else {
      await app.joinPublicChannel(channel.channelId, publicFilter: _filter);
      final joinedChannel = app.channels
          .where((it) => it.channelId == channel.channelId)
          .toList(growable: false);
      if (joinedChannel.isNotEmpty) {
        await app.selectChannel(joinedChannel.first);
      }
    }
    if (!context.mounted) return;
    final error = app.errorMessage;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.gB1BCFBTo393566),
        child: SafeArea(
          child: Consumer<AppController>(
            builder: (context, app, _) {
              final allPublicChannels = app.publicChannels.toList(
                growable: false,
              );
              final joinedIds = app.channels
                  .map((channel) => channel.channelId)
                  .toSet();
              bool resolveJoined(ChannelModel channel) {
                final category = (channel.listCategory ?? '')
                    .trim()
                    .toLowerCase();
                if (channel.isJoined != null) return channel.isJoined!;
                if (category == 'joined') return true;
                if (category == 'discover') return false;
                return joinedIds.contains(channel.channelId);
              }

              final normalizedQuery = _query.trim().toLowerCase();
              bool matchesQuery(ChannelModel channel) {
                final haystack = '${channel.name} ${channel.description ?? ''}'
                    .toLowerCase();
                return normalizedQuery.isEmpty ||
                    haystack.contains(normalizedQuery);
              }

              final filtered = allPublicChannels
                  .where(matchesQuery)
                  .toList(growable: false);

              final discoverTop =
                  allPublicChannels
                      .where(_isPublicGroupChannel)
                      .toList(growable: false)
                    ..sort(
                      (a, b) => (b.reputationScore ?? 0).compareTo(
                        a.reputationScore ?? 0,
                      ),
                    );
              final discoverTop10 = discoverTop
                  .take(10)
                  .toList(growable: false);
              final discoverRankById = <int, int>{
                for (var i = 0; i < discoverTop10.length; i++)
                  discoverTop10[i].channelId: i + 1,
              };
              final discoverVisible = discoverTop10
                  .where(matchesQuery)
                  .toList(growable: false);

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    app.refreshChannels(silent: true),
                    app.refreshPublicChannels(filter: _filter, silent: true),
                  ]);
                  if (!mounted) return;
                  setState(() {
                    _countsByFilter[_filter] = app.publicChannels.length;
                  });
                  await _refreshCountsForAll(app);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    Row(
                      children: [
                        const MojiBackButton(),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Rejoindre',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFontFamily,
                              color: AppColors.cFCFAFE,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 11.45),
                      decoration: BoxDecoration(
                        gradient: AppGradients.gB1BCFBTo393566,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: AppColors.whiteColor,
                            size: 27,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              style: const TextStyle(
                                color: AppColors.whiteColor,
                                fontFamily: AppTypography.primaryFontFamily,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              cursorColor: AppColors.whiteColor,
                              decoration: const InputDecoration(
                                hintText: 'Rechercher une conversation',
                                hintStyle: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontFamily: AppTypography.primaryFontFamily,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                filled: false,
                                fillColor: Colors.transparent,
                                isCollapsed: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PublicFilterBar(
                      selected: _filter,
                      allCount: _countsByFilter['all'] ?? 0,
                      joinedCount: _countsByFilter['joined'] ?? 0,
                      discoverCount: _countsByFilter['discover'] ?? 0,
                      onSelected: (value) {
                        if (_filter == value) return;
                        setState(() => _filter = value);
                        _loadFilter(app, value, showLoader: true);
                      },
                    ),
                    const SizedBox(height: 10),
                    if (_isSwitchingFilter)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.cFCFAFE,
                          ),
                        ),
                      )
                    else if ((_filter == 'discover'
                            ? discoverVisible
                            : filtered)
                        .isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text(
                            'Aucune conversation publique trouvee.',
                            style: TextStyle(color: AppColors.cDBE7FE),
                          ),
                        ),
                      )
                    else if (_filter == 'discover') ...[
                      const _DiscoverTopIntro(),
                      const SizedBox(height: 10),
                      ...discoverVisible.map((channel) {
                        final joined = resolveJoined(channel);
                        final rank = discoverRankById[channel.channelId] ?? 0;
                        return _DiscoverTopChannelTile(
                          channel: channel,
                          rank: rank,
                          joined: joined,
                          onActionTap: () => _handleJoinChannelTap(
                            context,
                            app,
                            channel,
                            joined,
                          ),
                        );
                      }),
                    ] else
                      ...filtered.map((channel) {
                        final joined = resolveJoined(channel);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.cFCFAFE.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AppRemoteImage(
                                  url: channel.coverImage,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  fallbackIcon: Icons.groups_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      channel.name,
                                      style: const TextStyle(
                                        color: AppColors.cFCFAFE,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      (channel.description ?? '').trim().isEmpty
                                          ? 'Groupe public'
                                          : channel.description!.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.cDBE7FE,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _handleJoinChannelTap(
                                  context,
                                  app,
                                  channel,
                                  joined,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.cFCFAFE,
                                  backgroundColor: AppColors.cFCFAFE.withValues(
                                    alpha: 0.10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(joined ? 'Ouvrir' : 'Rejoindre'),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PublicFilterBar extends StatelessWidget {
  const _PublicFilterBar({
    required this.selected,
    required this.allCount,
    required this.joinedCount,
    required this.discoverCount,
    required this.onSelected,
  });

  final String selected;
  final int allCount;
  final int joinedCount;
  final int discoverCount;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PublicFilterChip(
            label: 'Top',
            count: discoverCount,
            isActive: selected == 'discover',
            onTap: () => onSelected('discover'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PublicFilterChip(
            label: 'Rejoints',
            count: joinedCount,
            isActive: selected == 'joined',
            onTap: () => onSelected('joined'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PublicFilterChip(
            label: 'Tous',
            count: allCount,
            isActive: selected == 'all',
            onTap: () => onSelected('all'),
          ),
        ),
      ],
    );
  }
}

class _PublicFilterChip extends StatelessWidget {
  const _PublicFilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: isActive ? AppGradients.gB1BCFBTo393566 : null,
            color: isActive ? null : AppColors.cB1BCFB.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.whiteColor.withValues(
                alpha: isActive ? 0.35 : 0.24,
              ),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.whiteColor.withValues(
                      alpha: isActive ? 1 : 0.9,
                    ),
                    fontFamily: AppTypography.primaryFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor.withValues(
                    alpha: isActive ? 0.2 : 0.14,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.whiteColor,
                    fontFamily: AppTypography.primaryFontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverTopIntro extends StatelessWidget {
  const _DiscoverTopIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x4DFFD06A), Color(0x33D09EFE)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.24)),
      ),
      child: const Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD06A), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Top 10 des groupes publics par reputation',
              style: TextStyle(
                color: AppColors.cFCFAFE,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverTopChannelTile extends StatelessWidget {
  const _DiscoverTopChannelTile({
    required this.channel,
    required this.rank,
    required this.joined,
    required this.onActionTap,
  });

  final ChannelModel channel;
  final int rank;
  final bool joined;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final score = channel.reputationScore ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppGradients.gB1BCFBTo393566,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _DiscoverRankBadge(rank: rank),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppRemoteImage(
              url: channel.coverImage,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              fallbackIcon: Icons.groups_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.cFCFAFE,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cFCFAFE.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.cFCFAFE.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFFC86A),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Score: $score',
                        style: const TextStyle(
                          color: AppColors.cFCFAFE,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.cFCFAFE,
              backgroundColor: AppColors.cFCFAFE.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(joined ? 'Ouvrir' : 'Rejoindre'),
          ),
        ],
      ),
    );
  }
}

class _DiscoverRankBadge extends StatelessWidget {
  const _DiscoverRankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = _rankColors(rank);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cFCFAFE.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$rank',
        style: const TextStyle(
          color: AppColors.c121212,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }

  List<Color> _rankColors(int value) {
    if (value == 1) return const [Color(0xFFFFE08A), Color(0xFFFFC34D)];
    if (value == 2) return const [Color(0xFFE9EFFA), Color(0xFFBCC7DB)];
    if (value == 3) return const [Color(0xFFF4C9A2), Color(0xFFD9946D)];
    return const [Color(0xFFDCC8FF), Color(0xFFBFA0F7)];
  }
}
