import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/chat_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/local_db_service.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;

  const ChatRoomScreen({super.key, required this.roomId, required this.roomName});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;
  int _lastTs = 0;
  ChatMessage? _replyTo;
  ChatMessage? _pinnedMsg;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
    _loadPinned();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    // Load from cache first
    final cached = await LocalDbService.instance.getChatMessages(widget.roomId);
    if (mounted && cached.isNotEmpty) {
      setState(() {
        _messages.clear();
        _messages.addAll(cached.map((m) => ChatMessage.fromJson(m)));
        _lastTs = _messages.isNotEmpty ? _messages.last.ts : 0;
        _loading = false;
      });
      _scrollToBottom();
    }
    // Then fetch from server
    await _fetchMessages();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchMessages() async {
    if (!ApiService.instance.isConfigured) return;
    final result = await ApiService.instance.fetchMessages(widget.roomId, _lastTs);
    if (result?['ok'] == true && result?['msgs'] != null) {
      final newMsgs = (result!['msgs'] as List<dynamic>)
          .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      for (final msg in newMsgs) {
        await LocalDbService.instance.saveChatMessage(widget.roomId, msg.toJson());
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx >= 0) {
          _messages[idx] = msg;
        } else {
          _messages.add(msg);
        }
        if (msg.ts > _lastTs) _lastTs = msg.ts;
      }
      if (mounted && newMsgs.isNotEmpty) {
        _messages.sort((a, b) => a.ts.compareTo(b.ts));
        setState(() {});
        _scrollToBottom();
      }
    }
  }

  Future<void> _loadPinned() async {
    if (!ApiService.instance.isConfigured) return;
    final result = await ApiService.instance.getPinned(widget.roomId);
    if (result?['ok'] == true && result?['msg'] != null) {
      if (mounted) {
        setState(() => _pinnedMsg = ChatMessage.fromJson(Map<String, dynamic>.from(result!['msg'])));
      }
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.chatPollIntervalMs),
      (_) => _fetchMessages(),
    );
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _sending = true);
    _textCtrl.clear();

    final now = DateTime.now().millisecondsSinceEpoch;
    final msg = ChatMessage(
      id: 'm_${user.uid}_$now',
      roomId: widget.roomId,
      uid: user.uid,
      senderName: user.name,
      senderRole: user.role,
      text: text,
      ts: now,
      replyToId: _replyTo?.id,
      replyToText: _replyTo?.text,
      replyToSender: _replyTo?.senderName,
    );

    // Optimistic update
    setState(() { _messages.add(msg); _replyTo = null; });
    _scrollToBottom();

    await ApiService.instance.sendMessage(widget.roomId, msg.toJson());
    await LocalDbService.instance.saveChatMessage(widget.roomId, msg.toJson());

    if (mounted) setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessageActions(ChatMessage msg) {
    final user = ref.read(currentUserProvider);
    final isAdmin = user?.isAdminLike ?? false;
    final isOwn = msg.uid == user?.uid;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('رد'),
            onTap: () { setState(() => _replyTo = msg); Navigator.pop(ctx); },
          ),
          if (isAdmin) ListTile(
            leading: const Icon(Icons.push_pin),
            title: Text(msg.pinned ? 'إلغاء التثبيت' : 'تثبيت'),
            onTap: () async {
              if (msg.pinned) {
                await ApiService.instance.unpinMessage(widget.roomId);
                setState(() => _pinnedMsg = null);
              } else {
                await ApiService.instance.pinMessage(widget.roomId, msg.toJson());
                setState(() => _pinnedMsg = msg);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          if (isAdmin || isOwn) ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('حذف', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await ApiService.instance.deleteMessage(widget.roomId, msg.id);
              setState(() {
                final idx = _messages.indexWhere((m) => m.id == msg.id);
                if (idx >= 0) _messages[idx] = ChatMessage(
                  id: msg.id, roomId: msg.roomId, uid: msg.uid,
                  senderName: msg.senderName, text: '', ts: msg.ts, deleted: true,
                );
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          if (isAdmin && !isOwn) ListTile(
            leading: const Icon(Icons.block, color: AppColors.warning),
            title: const Text('حظر من الشات'),
            onTap: () async {
              await ApiService.instance.chatBan(msg.uid, true);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName),
            Text('${_messages.length} رسالة', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      body: Column(
        children: [
          // Pinned message
          if (_pinnedMsg != null)
            Container(
              color: theme.colorScheme.primary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.push_pin, size: 14, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_pinnedMsg!.text, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await ApiService.instance.unpinMessage(widget.roomId);
                      setState(() => _pinnedMsg = null);
                    },
                    child: const Icon(Icons.close, size: 14),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(child: Text('لا توجد رسائل بعد', style: theme.textTheme.bodyMedium))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) => _MessageBubble(
                          msg: _messages[i],
                          isMe: _messages[i].uid == user?.uid,
                          theme: theme,
                          onLongPress: () => _showMessageActions(_messages[i]),
                        ),
                      ),
          ),

          // Reply bar
          if (_replyTo != null)
            Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_replyTo!.senderName, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                        Text(_replyTo!.text, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _replyTo = null)),
                ],
              ),
            ),

          // Input
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _sending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  onPressed: _sending ? null : _send,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final ThemeData theme;
  final VoidCallback onLongPress;

  const _MessageBubble({required this.msg, required this.isMe, required this.theme, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    if (msg.deleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(child: Text('🗑 تم حذف هذه الرسالة',
            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic))),
      );
    }

    final isAdmin = ['SUPER_ADMIN', 'ADMIN', 'COACH'].contains(msg.senderRole.toUpperCase());

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(msg.senderName.isNotEmpty ? msg.senderName[0] : '?',
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe) Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(msg.senderName, style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isAdmin ? AppColors.goldColor : theme.colorScheme.primary,
                          fontSize: 12,
                        )),
                        if (isAdmin) const Text(' 🌟', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    if (msg.replyToText != null) Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg.replyToSender ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          Text(msg.replyToText!, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text(msg.text,
                        style: TextStyle(color: isMe ? Colors.white : null, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(msg.dateTime),
                      style: TextStyle(
                        color: isMe ? Colors.white60 : theme.textTheme.bodySmall?.color,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
