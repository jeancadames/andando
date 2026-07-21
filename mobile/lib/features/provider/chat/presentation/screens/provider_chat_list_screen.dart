// lib/features/provider/chat/presentation/screens/provider_chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/application/auth_controller.dart';
import '../../../../chat/data/models/chat_conversation_model.dart';
import '../../data/services/provider_chat_service.dart';
import '../../../../../shared/widgets/provider_bottom_nav.dart';

class ProviderChatListScreen extends StatefulWidget {
  final AuthController authController;

  const ProviderChatListScreen({super.key, required this.authController});

  @override
  State<ProviderChatListScreen> createState() => _ProviderChatListScreenState();
}

class _ProviderChatListScreenState extends State<ProviderChatListScreen> {
  final ProviderChatService _service = ProviderChatService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ChatConversationModel> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final conversations = await _service.getConversations(
        token: widget.authController.token,
      );

      if (!mounted) return;

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } on ProviderChatException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'No pudimos cargar los mensajes de clientes.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final conversations = await _service.getConversations(
        token: widget.authController.token,
      );

      if (!mounted) return;

      setState(() {
        _conversations = conversations;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos actualizar los mensajes.')),
      );
    }
  }

  void _openConversation(ChatConversationModel conversation) {
    context.push('/provider/messages/${conversation.id}', extra: conversation);
  }

  @override
  Widget build(BuildContext context) {
    final totalUnread = _conversations.fold<int>(
      0,
      (total, item) => total + item.unreadCount,
    );

    final notice = _conversations.isNotEmpty
        ? _conversations.first.inactivityNotice
        : 'Los chats se cierran automáticamente después de 72 horas sin interacción.';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _ProviderMessagesHeader(unreadCount: totalUnread),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: _NoticeBox(text: notice),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: _errorMessage!,
                    onRetry: _loadConversations,
                  ),
                )
              else if (_conversations.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  sliver: SliverList.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];

                      return _ProviderConversationCard(
                        conversation: conversation,
                        onTap: () => _openConversation(conversation),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ProviderBottomNav(
        authController: widget.authController,
        messagesUnreadCount: totalUnread,
      ),
    );
  }
}

class _ProviderMessagesHeader extends StatelessWidget {
  final int unreadCount;

  const _ProviderMessagesHeader({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mensajes de clientes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unreadCount > 0
                ? 'Tienes $unreadCount mensaje(s) sin leer'
                : 'Responde dudas antes de que tus clientes reserven',
            style: TextStyle(
              fontSize: 15,
              color: unreadCount > 0
                  ? const Color(0xFF003B73)
                  : const Color(0xFF6B7280),
              fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderConversationCard extends StatelessWidget {
  final ChatConversationModel conversation;
  final VoidCallback onTap;

  const _ProviderConversationCard({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = conversation.experience?.coverPhotoUrl;
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 68,
                        height: 68,
                        child: hasImage
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _ImagePlaceholder(),
                              )
                            : const _ImagePlaceholder(),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF003B73),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          if (conversation.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF003B73),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.travel_explore_rounded,
                            size: 15,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              conversation.experienceTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        conversation.displayLastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: conversation.unreadCount > 0
                              ? const Color(0xFF111827)
                              : const Color(0xFF64748B),
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (conversation.isClosed)
                            const _StatusChip(
                              text: 'Cerrado',
                              color: Color(0xFF991B1B),
                              backgroundColor: Color(0xFFFEE2E2),
                            )
                          else
                            const _StatusChip(
                              text: 'Abierto',
                              color: Color(0xFF047857),
                              backgroundColor: Color(0xFFD1FAE5),
                            ),
                          const SizedBox(width: 8),
                          if (conversation.booking != null)
                            const _StatusChip(
                              text: 'Con reserva',
                              color: Color(0xFF075985),
                              backgroundColor: Color(0xFFE0F2FE),
                            ),
                          const Spacer(),
                          Text(
                            _formatDate(conversation.lastMessageAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final local = date.toLocal();

    final isToday =
        now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;

    if (isToday) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    }

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }
}

class _NoticeBox extends StatelessWidget {
  final String text;

  const _NoticeBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF003B73),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final Color backgroundColor;

  const _StatusChip({
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE9D2D8),
      child: const Center(
        child: Icon(Icons.travel_explore_rounded, color: Color(0xFF94A3B8)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 42,
                color: Color(0xFF003B73),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aún no tienes mensajes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando un cliente te contacte por una experiencia, la conversación aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 58,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 14),
            const Text(
              'No pudimos cargar tus mensajes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF003B73),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
