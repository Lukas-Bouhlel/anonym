import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/channel_message_model.dart';
import '../models/channel_model.dart';
import '../models/user_model.dart';
import '../providers/app_providers.dart';
import '../providers/auth_providers.dart';
import 'group_settings_screen.dart';
import 'user_profile_screen.dart';
import '../theme.dart';
import '../utils/app_date_format.dart';
import '../utils/group_invite_payload.dart';
import '../utils/profile_share_payload.dart';
import '../utils/presence_utils.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/navigation/anonym_back_button.dart';
import '../widgets/dialogs/anonym_confirm_dialog.dart';
import '../widgets/presence_badge.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:image_picker/image_picker.dart';



part '../widgets/channels/channel_sheet_widgets.dart';
part '../widgets/channels/channel_list_widgets.dart';
part '../widgets/channels/channel_chat_widgets.dart';
part '../widgets/channels/channel_chat_extra_widgets.dart';
part '../widgets/channels_screen_widgets.dart';

/// Écran de conversation: liste des canaux et zone de chat.
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
  final Set<int> _hydratedDmPeerIds = <int>{};

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;
    final t = Theme.of(context).textTheme;

    return Consumer<AppProvider>(
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
            context.read<AppProvider>().clearMessageError();
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
          final dmPeerBase = hasMemberPeer
              ? dmPeerFromMembers
              : selected.dmPeer;
          if (isDm && dmPeerBase != null && dmPeerBase.id > 0) {
            _hydrateDmPeerDetailsIfNeeded(app, dmPeerBase.id);
          }
          final dmPeer = dmPeerBase != null && dmPeerBase.id > 0
              ? (app.userById(dmPeerBase.id) ?? dmPeerBase)
              : dmPeerBase;
          final dmPeerForFrame = dmPeerBase != null && dmPeerBase.id > 0
              ? (app.userById(dmPeerBase.id) ?? dmPeerBase)
              : null;
          final dmPeerName = (dmPeer?.username ?? '').trim();
          final hasDmPeerName = dmPeerName.isNotEmpty;
          return _ChatDetailView(
            currentUserId: currentUser?.id,
            currentUserName: currentUser?.username,
            currentUserAvatarUrl: currentUser?.avatar,
            currentUserFrameUrl: _activeFrameUrlFromUser(app, currentUser),
            isDm: isDm,
            dmPeerName: hasDmPeerName ? dmPeerName : null,
            dmPeerAvatarUrl: dmPeer?.avatar,
            dmPeerFrameUrl: isDm
                ? _activeFrameUrlFromUser(app, dmPeerForFrame)
                : null,
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

  void _hydrateDmPeerDetailsIfNeeded(AppProvider app, int userId) {
    if (userId <= 0) return;
    if (_hydratedDmPeerIds.contains(userId)) return;
    _hydratedDmPeerIds.add(userId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(app.hydrateUserDetails(userId));
    });
  }

  void _sendText(AppProvider app) {
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
    AppProvider app,
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
    AppProvider app,
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
                  label: 'Rejoindre un groupe',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _openJoinPublicDirectoryScreen(parentContext, app);
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openJoinPublicDirectoryScreen(
    BuildContext context,
    AppProvider app,
  ) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PublicConversationsScreen(),
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

  String? _activeFrameUrlFromUser(AppProvider app, UserModel? user) {
    if (user == null || user.id <= 0) return null;
    for (final item in user.inventories) {
      if (!item.active) continue;
      if (item.userId > 0 && item.userId != user.id) continue;
      final fromInventory = item.shop;
      if (fromInventory != null) {
        final content = fromInventory.content.trim();
        if (content.isEmpty) continue;
        final type = fromInventory.type.trim().toUpperCase();
        if (type == 'CADRE') return content;
      }
      for (final shopItem in app.shopItems) {
        if (shopItem.articleId != item.articleId) continue;
        final content = shopItem.content.trim();
        if (content.isEmpty) continue;
        final type = shopItem.type.trim().toUpperCase();
        if (type == 'CADRE') return content;
      }
    }
    return null;
  }

  Future<void> _deleteMessage(
    BuildContext context,
    AppProvider app,
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
    AppProvider app,
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
    AppProvider app,
  ) async {
    final parentContext = context;
    final selected = app.selectedChannel;
    if (selected == null) return;
    final isPrivateDm =
        selected.channelType.trim().toUpperCase() == 'PRIVATE_DM';
    if (isPrivateDm) return;
    final currentUserId = context.read<AuthProvider>().user?.id;
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
                        if (!parentContext.mounted) return;
                        await Navigator.of(parentContext).push(
                          PageRouteBuilder<void>(
                            transitionDuration: const Duration(
                              milliseconds: 260,
                            ),
                            reverseTransitionDuration: const Duration(
                              milliseconds: 220,
                            ),
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    GroupSettingsScreen(channel: selected),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  final offset =
                                      Tween<Offset>(
                                        begin: const Offset(1, 0),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      );
                                  return SlideTransition(
                                    position: offset,
                                    child: child,
                                  );
                                },
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
                      if (!parentContext.mounted) return;
                      await _showMembersSheet(parentContext, app, selected);
                    },
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.link_rounded,
                    label: 'Créer une invitation',
                    onTap: () async {
                      Navigator.of(context).pop();
                      if (!parentContext.mounted) return;
                      await _showInviteSheet(parentContext, app, selected);
                    },
                  ),
                  if (!isCreator) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.logout_rounded,
                      label: 'Quitter le groupe',
                      onTap: () async {
                        Navigator.of(context).pop();
                        if (!parentContext.mounted) return;
                        final shouldLeave = await _confirmLeaveGroup(
                          parentContext,
                          selected,
                        );
                        if (!shouldLeave) return;
                        await app.leaveSelectedChannel();
                        if (!parentContext.mounted) return;
                        if (app.errorMessage != null &&
                            app.errorMessage!.isNotEmpty) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(content: Text(app.errorMessage!)),
                          );
                        }
                      },
                    ),
                  ],
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
    AppProvider app,
    ChannelModel channel,
  ) async {
    final selectedChannelId = app.selectedChannel?.channelId;
    if (selectedChannelId != channel.channelId) {
      await app.selectChannel(channel);
    }
    if (!context.mounted) return;
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isHost = currentUserId != null && channel.createdBy == currentUserId;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<AppProvider>(
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
      builder: (dialogContext) => AnonymConfirmDialog(
        type: AnonymConfirmDialogType.danger,
        title: 'Exclure $username ?',
        description: 'Cette action retire immediatement ce membre du groupe.',
        confirmLabel: 'Exclure',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return confirmed == true;
  }

  Future<bool> _confirmLeaveGroup(
    BuildContext context,
    ChannelModel channel,
  ) async {
    final groupName = channel.name.trim();
    final safeName = groupName.isEmpty ? 'ce groupe' : groupName;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AnonymConfirmDialog(
        type: AnonymConfirmDialogType.warning,
        title: 'Quitter $safeName ?',
        description:
            'Tu ne recevras plus les messages du groupe. Tu pourras le rejoindre de nouveau plus tard.',
        confirmLabel: 'Quitter',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return confirmed == true;
  }

  Future<void> _showInviteSheet(
    BuildContext context,
    AppProvider app,
    ChannelModel channel,
  ) async {
    await app.selectChannel(channel);
    if (!context.mounted) return;

    var query = '';
    final invitedUserIds = <int>{};
    final selectedUserIds = <int>{};
    bool isInvitingUsers = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      textAlign: TextAlign.center,
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
                                'Aucun ami à inviter',
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
                                final resolvedUser =
                                    app.userById(user.id) ?? user;
                                final frameUrl = _activeFrameUrlFromUser(
                                  app,
                                  resolvedUser,
                                );
                                final invited = invitedUserIds.contains(
                                  user.id,
                                );
                                final selectedForInvite = selectedUserIds
                                    .contains(user.id);
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: AppColors.c393566,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.cFCFAFE
                                                  .withValues(alpha: 0.18),
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: AppRemoteImage(
                                              url: resolvedUser.avatar,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              fallbackIcon:
                                                  Icons.person_outline,
                                            ),
                                          ),
                                        ),
                                        if (frameUrl != null)
                                          IgnorePointer(
                                            child: AppRemoteImage(
                                              url: frameUrl,
                                              width: 42,
                                              height: 42,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                      ],
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
                                  trailing: SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: invited
                                            ? AppColors.cFCFAFE.withValues(
                                                alpha: 0.18,
                                              )
                                            : selectedForInvite
                                            ? AppColors.cFCFAFE.withValues(
                                                alpha: 0.20,
                                              )
                                            : AppColors.cFCFAFE.withValues(
                                                alpha: 0.08,
                                              ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.cFCFAFE.withValues(
                                            alpha: 0.28,
                                          ),
                                        ),
                                      ),
                                      child: Checkbox(
                                        value: invited
                                            ? true
                                            : selectedForInvite,
                                        onChanged: invited
                                            ? null
                                            : (value) {
                                                setModalState(() {
                                                  if (value == true) {
                                                    selectedUserIds.add(
                                                      user.id,
                                                    );
                                                  } else {
                                                    selectedUserIds.remove(
                                                      user.id,
                                                    );
                                                  }
                                                });
                                              },
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        side: BorderSide(
                                          color: AppColors.cFCFAFE.withValues(
                                            alpha: 0.60,
                                          ),
                                          width: 1.4,
                                        ),
                                        checkColor: AppColors.c393566,
                                        activeColor: AppColors.cFCFAFE,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: isInvitingUsers || selectedUserIds.isEmpty
                              ? null
                              : AppGradients.gB1BCFBTo393566,
                          color: isInvitingUsers || selectedUserIds.isEmpty
                              ? AppColors.cFCFAFE.withValues(alpha: 0.08)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.cFCFAFE.withValues(alpha: 0.25),
                          ),
                        ),
                        child: FilledButton(
                          onPressed: isInvitingUsers || selectedUserIds.isEmpty
                              ? null
                              : () async {
                                  setModalState(() => isInvitingUsers = true);
                                  final targetUserIds = selectedUserIds
                                      .where(
                                        (id) => !invitedUserIds.contains(id),
                                      )
                                      .toList(growable: false);
                                  await app.inviteUsersToSelectedChannel(
                                    targetUserIds,
                                  );
                                  if (!context.mounted) return;
                                  final error = app.errorMessage;
                                  if (error != null && error.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error)),
                                    );
                                    setModalState(
                                      () => isInvitingUsers = false,
                                    );
                                    return;
                                  }
                                  setModalState(() {
                                    invitedUserIds.addAll(targetUserIds);
                                    selectedUserIds.removeAll(targetUserIds);
                                    isInvitingUsers = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        targetUserIds.length > 1
                                            ? '${targetUserIds.length} invitations envoyées.'
                                            : 'Invitation envoyée.',
                                      ),
                                    ),
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            foregroundColor: AppColors.cFCFAFE,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isInvitingUsers
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.cFCFAFE,
                                  ),
                                )
                              : Text(
                                  selectedUserIds.isEmpty
                                      ? 'Sélectionner des amis'
                                      : selectedUserIds.length == 1
                                      ? 'Inviter 1\'ami'
                                      : 'Inviter ${selectedUserIds.length} amis',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
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
