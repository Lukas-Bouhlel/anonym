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
import '../theme.dart';
import '../utils/app_date_format.dart';
import '../widgets/app_remote_image.dart';
import '../widgets/chrome/moji_back_button.dart';

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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final bottomSafe = MediaQuery.of(context).padding.bottom;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            padding: EdgeInsets.fromLTRB(12, 10, 12, 14 + bottomSafe),
            decoration: BoxDecoration(
              gradient: AppGradients.gB1BCFBTo393566,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: AppColors.cFCFAFE.withValues(alpha: 0.3),
              ),
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
                  _InfoRow(
                    icon: Icons.public_rounded,
                    label: 'Creer un groupe public',
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _showCreateGroupDialog(
                        context,
                        app,
                        visibility: 'PUBLIC',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Creer un groupe prive',
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _showCreateGroupDialog(
                        context,
                        app,
                        visibility: 'PRIVATE',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Creer une conversation DM',
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _showCreateDmDialog(context, app);
                    },
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.login_rounded,
                    label: 'Rejoindre un groupe public (ID)',
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _showJoinPublicDialog(context, app);
                    },
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.vpn_key_outlined,
                    label: 'Rejoindre via code invitation',
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _showJoinByCodeDialog(context, app);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateGroupDialog(
    BuildContext context,
    AppController app, {
    required String visibility,
  }) async {
    String name = '';
    String description = '';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return _ActionSheetContainer(
                  title: visibility == 'PUBLIC'
                      ? 'Creer un groupe public'
                      : 'Creer un groupe prive',
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) => setModalState(() => name = value),
                        style: const TextStyle(color: AppColors.cFCFAFE),
                        decoration: const InputDecoration(
                          labelText: 'Nom du channel',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (value) =>
                            setModalState(() => description = value),
                        style: const TextStyle(color: AppColors.cFCFAFE),
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final normalizedName = name.trim();
                            if (normalizedName.isEmpty) return;
                            await app.createGroupChannel(
                              name: normalizedName,
                              description: description.trim(),
                              visibility: visibility,
                            );
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                          child: const Text('Creer'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateDmDialog(
    BuildContext context,
    AppController app,
  ) async {
    final activeFriends = app.friends
        .where((friend) => friend.status.trim().toUpperCase() == 'ACTIVE')
        .where((friend) => friend.friendDetails != null)
        .toList(growable: false);
    if (activeFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun ami actif disponible pour creer un DM.'),
        ),
      );
      return;
    }

    int? selectedUserId = activeFriends.first.friendId;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setInnerState) {
              return _ActionSheetContainer(
                title: 'Creer une conversation DM',
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedUserId,
                      dropdownColor: AppColors.c393566,
                      decoration: const InputDecoration(labelText: 'Ami'),
                      items: activeFriends
                          .map(
                            (friend) => DropdownMenuItem<int>(
                              value: friend.friendId,
                              child: Text(
                                friend.friendDetails?.username.isNotEmpty ==
                                        true
                                    ? friend.friendDetails!.username
                                    : 'User #${friend.friendId}',
                                style: const TextStyle(
                                  color: AppColors.cFCFAFE,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setInnerState(() => selectedUserId = value),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (selectedUserId == null) return;
                          await app.createPrivateDm(
                            targetUserId: selectedUserId!,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                        child: const Text('Creer'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showJoinPublicDialog(
    BuildContext context,
    AppController app,
  ) async {
    String channelIdValue = '';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return _ActionSheetContainer(
                  title: 'Rejoindre un groupe public',
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) =>
                            setModalState(() => channelIdValue = value),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.cFCFAFE),
                        decoration: const InputDecoration(
                          labelText: 'Channel ID',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final channelId = int.tryParse(
                              channelIdValue.trim(),
                            );
                            if (channelId == null) return;
                            await app.joinPublicChannel(channelId);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                          child: const Text('Rejoindre'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showJoinByCodeDialog(
    BuildContext context,
    AppController app,
  ) async {
    String code = '';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return _ActionSheetContainer(
                  title: 'Rejoindre via invitation',
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) => setModalState(() => code = value),
                        style: const TextStyle(color: AppColors.cFCFAFE),
                        decoration: const InputDecoration(
                          labelText: 'Code invitation',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final normalized = code.trim();
                            if (normalized.isEmpty) return;
                            await app.joinByInviteCode(normalized);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                          child: const Text('Rejoindre'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final members = app.channelMembers;
        final bottomSafe = MediaQuery.of(context).padding.bottom;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          padding: EdgeInsets.fromLTRB(14, 10, 14, 16 + bottomSafe),
          decoration: BoxDecoration(
            gradient: AppGradients.gB1BCFBTo393566,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _MemberAvatar(member: member),
                      title: Text(
                        member.username.isNotEmpty
                            ? member.username
                            : 'User #${member.id}',
                        style: const TextStyle(color: AppColors.cFCFAFE),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
