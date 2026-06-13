import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/chat_model.dart';
import '../../../providers/auth_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    final rooms = _buildRooms(l10n, user?.isAdminLike ?? false, user?.featureAllowed('chat_coach') ?? false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chat)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI chat
          if (user?.featureAllowed('ai_chat') ?? false)
            _ChatRoomCard(
              icon: '🤖',
              title: l10n.aiChat,
              subtitle: 'مساعد ذكي متخصص في التدريب',
              color: const Color(0xFF7C6EFF),
              onTap: () => context.push('/chat/room', extra: {'roomId': 'ai', 'roomName': l10n.aiChat}),
            ),

          // Rooms
          ...rooms.map((room) => _ChatRoomCard(
            icon: room.icon,
            title: l10n.isAr ? room.nameAr : room.name,
            subtitle: '',
            color: _roomColor(room.id),
            onTap: () => context.push('/chat/room', extra: {'roomId': room.id, 'roomName': l10n.isAr ? room.nameAr : room.name}),
          )),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<ChatRoom> _buildRooms(AppLocalizations l10n, bool isAdmin, bool canCoachChat) {
    final rooms = <ChatRoom>[
      ChatRoom(id: 'general', name: 'General', nameAr: l10n.generalChat, icon: '💬'),
      ChatRoom(id: 'announcements', name: 'Announcements', nameAr: l10n.announcements, icon: '📢'),
    ];
    if (canCoachChat || isAdmin) {
      rooms.add(ChatRoom(id: 'coach', name: 'Coach', nameAr: l10n.coachChat, icon: '👨‍🏫'));
    }
    if (isAdmin) {
      rooms.add(ChatRoom(id: 'support', name: 'Support', nameAr: l10n.supportChat, icon: '🔧'));
    }
    return rooms;
  }

  Color _roomColor(String id) {
    switch (id) {
      case 'general': return AppColors.primaryGreen;
      case 'announcements': return Colors.orange;
      case 'coach': return Colors.blue;
      case 'support': return Colors.purple;
      default: return AppColors.accent;
    }
  }
}

class _ChatRoomCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChatRoomCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    if (subtitle.isNotEmpty) Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
