// lib/features/customer/chat/presentation/screens/customer_chat_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../auth/application/auth_controller.dart';
import '../../../../chat/data/models/chat_conversation_model.dart';
import '../../../../chat/data/models/chat_message_model.dart';
import '../../data/services/customer_chat_service.dart';

import 'package:flutter/foundation.dart';

class CustomerChatScreen extends StatefulWidget {
  final AuthController authController;
  final int conversationId;
  final ChatConversationModel? initialConversation;

  const CustomerChatScreen({
    super.key,
    required this.authController,
    required this.conversationId,
    this.initialConversation,
  });

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final CustomerChatService _service = CustomerChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  Timer? _pollingTimer;

  ChatConversationModel? _conversation;
  List<ChatMessageModel> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  bool get _isClosed {
    return _conversation?.isClosed == true;
  }

  @override
  void initState() {
    super.initState();

    _conversation = widget.initialConversation;
    _loadInitialData();

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollMessages(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final conversation = await _service.getConversation(
        token: widget.authController.token,
        conversationId: widget.conversationId,
      );

      final messages = await _service.getMessages(
        token: widget.authController.token,
        conversationId: widget.conversationId,
      );

      await _service.markAsRead(
        token: widget.authController.token,
        conversationId: widget.conversationId,
      );

      if (!mounted) return;

      setState(() {
        _conversation = conversation;
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();
    } on CustomerChatException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'No pudimos cargar esta conversación.';
        _isLoading = false;
      });
    }
  }

  Future<void> _pollMessages() async {
    if (!mounted || _isLoading || _isSending) {
      return;
    }

    try {
      final messages = await _service.getMessages(
        token: widget.authController.token,
        conversationId: widget.conversationId,
      );

      final conversation = await _service.getConversation(
        token: widget.authController.token,
        conversationId: widget.conversationId,
      );

      await _service.markAsRead(
        token: widget.authController.token,
        conversationId: widget.conversationId,
      );

      if (!mounted) return;

      final oldLastId = _messages.isEmpty ? null : _messages.last.id;
      final newLastId = messages.isEmpty ? null : messages.last.id;

      setState(() {
        _messages = messages;
        _conversation = conversation;
      });

      if (oldLastId != newLastId) {
        _scrollToBottom();
      }
    } catch (_) {
      // No mostramos error en polling para no molestar al usuario.
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending || _isClosed) {
      return;
    }

    await _sendMessage(message: text);
  }

  Future<void> _pickAndSendImage() async {
    if (_isSending || _isClosed) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    await _sendMessage(
      message: _messageController.text.trim(),
      image: image,
    );
  }

  Future<void> _sendMessage({
    String? message,
    XFile? image,
  }) async {
    setState(() {
      _isSending = true;
    });

    try {
      final sentMessage = await _service.sendMessage(
        token: widget.authController.token,
        conversationId: widget.conversationId,
        message: message,
        image: image,
      );

      if (!mounted) return;

      _messageController.clear();

      setState(() {
        _messages = [
          ..._messages.where((item) => item.id != sentMessage.id),
          sentMessage,
        ];
      });

      await _reloadConversationSilently();

      _scrollToBottom();
    } on CustomerChatException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );

      await _reloadConversationSilently();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar el mensaje.'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _reloadConversationSilently() async {
    try {
      final conversation = await _service.getConversation(
        token: widget.authController.token,
        conversationId: widget.conversationId,
      );

      if (!mounted) return;

      setState(() {
        _conversation = conversation;
      });
    } catch (_) {
      // Silencioso.
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _openImage(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              InteractiveViewer(
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _title {
    final conversation = _conversation;

    if (conversation == null) {
      return 'Chat';
    }

    return conversation.providerName;
  }

  String get _subtitle {
    final conversation = _conversation;

    if (conversation == null) {
      return '';
    }

    return conversation.experienceTitle;
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (_subtitle.trim().isNotEmpty)
              Text(
                _subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (conversation != null)
              _ChatNoticeBox(
                text: conversation.isClosed
                    ? 'Este chat fue cerrado automáticamente por inactividad.'
                    : conversation.inactivityNotice,
                isClosed: conversation.isClosed,
              ),
            Expanded(
              child: _buildBody(),
            ),
            _MessageInputBar(
              controller: _messageController,
              isSending: _isSending,
              isClosed: _isClosed,
              onSend: _sendTextMessage,
              onPickImage: _pickAndSendImage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _loadInitialData,
      );
    }

    if (_messages.isEmpty) {
      return const _EmptyMessagesState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];

        return _MessageBubble(
          message: message,
          isMine: message.senderType == 'customer',
          onOpenImage: _openImage,
        );
      },
    );
  }
}

class _ChatNoticeBox extends StatelessWidget {
  final String text;
  final bool isClosed;

  const _ChatNoticeBox({
    required this.text,
    required this.isClosed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isClosed
        ? const Color(0xFFFFF1F2)
        : const Color(0xFFEFF6FF);

    final borderColor = isClosed
        ? const Color(0xFFFECDD3)
        : const Color(0xFFBFDBFE);

    final iconColor = isClosed
        ? const Color(0xFFBE123C)
        : const Color(0xFF003B73);

    final textColor = isClosed
        ? const Color(0xFF9F1239)
        : const Color(0xFF1E3A8A);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isClosed
                ? Icons.lock_clock_rounded
                : Icons.info_outline_rounded,
            color: iconColor,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;
  final ValueChanged<String> onOpenImage;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onOpenImage,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;

    final bubbleColor = isMine
        ? const Color(0xFF003B73)
        : Colors.white;

    final textColor = isMine
        ? Colors.white
        : const Color(0xFF111827);

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMine ? 20 : 5),
      bottomRight: Radius.circular(isMine ? 5 : 20),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 310),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
                border: isMine
                    ? null
                    : Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasImage)
                    GestureDetector(
                      onTap: () => onOpenImage(message.attachmentUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          message.attachmentUrl!,
                          width: 230,
                          height: 160,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;

                            return Container(
                              width: 230,
                              height: 160,
                              color: const Color(0xFFE5E7EB),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (_, error, stackTrace) {
                            debugPrint('ERROR CARGANDO IMAGEN CHAT: $error');
                            debugPrint('URL IMAGEN CHAT: ${message.attachmentUrl}');

                            return Container(
                              width: 230,
                              height: 160,
                              color: const Color(0xFFE5E7EB),
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Color(0xFF64748B),
                              ),
                            );
                          },
                        )
                      ),
                    ),
                  if (message.hasImage && message.hasText)
                    const SizedBox(height: 10),
                  if (message.hasText)
                    Text(
                      message.message!,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.35,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime? date) {
    if (date == null) return '';

    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isClosed;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  const _MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.isClosed,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    if (isClosed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.black.withOpacity(0.08),
            ),
          ),
        ),
        child: const Text(
          'Este chat está cerrado por inactividad. Puedes volver a contactar al afiliado desde la experiencia.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withOpacity(0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isSending ? null : onPickImage,
            icon: const Icon(
              Icons.image_outlined,
              color: Color(0xFF003B73),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                enabled: !isSending,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            height: 46,
            child: ElevatedButton(
              onPressed: isSending ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003B73),
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  const _EmptyMessagesState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Aún no hay mensajes en este chat.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003B73),
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