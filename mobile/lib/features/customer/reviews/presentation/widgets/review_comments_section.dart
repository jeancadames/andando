import 'package:flutter/material.dart';

import '../../data/datasources/review_comments_remote_datasource.dart';
import '../../data/models/review_comment_model.dart';

class ReviewCommentsSection extends StatefulWidget {
  const ReviewCommentsSection({
    super.key,
    required this.reviewId,
    required this.initialCommentsCount,
  });

  final int reviewId;
  final int initialCommentsCount;

  @override
  State<ReviewCommentsSection> createState() => _ReviewCommentsSectionState();
}

class _ReviewCommentsSectionState extends State<ReviewCommentsSection> {
  final ReviewCommentsRemoteDataSource _dataSource =
      ReviewCommentsRemoteDataSource();

  final TextEditingController _commentController = TextEditingController();

  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<ReviewCommentModel> _comments = [];

  int get _commentsCount {
    if (_comments.isNotEmpty) return _comments.length;
    return widget.initialCommentsCount;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final comments = await _dataSource.getComments(
        reviewId: widget.reviewId,
      );

      if (!mounted) return;

      setState(() {
        _comments = comments;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleExpanded() async {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
      return;
    }

    setState(() => _isExpanded = true);

    await _loadComments();
  }

  Future<void> _submitComment() async {
    final comment = _commentController.text.trim();

    if (comment.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final created = await _dataSource.createComment(
        reviewId: widget.reviewId,
        comment: comment,
      );

      if (!mounted) return;

      setState(() {
        _comments = [
          created,
          ..._comments,
        ];
        _commentController.clear();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _deleteComment(ReviewCommentModel comment) async {
    try {
      await _dataSource.deleteComment(
        commentId: comment.id,
      );

      if (!mounted) return;

      setState(() {
        _comments.removeWhere((item) => item.id == comment.id);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _editComment(ReviewCommentModel comment) async {
    final controller = TextEditingController(text: comment.comment);

    final updatedText = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar comentario'),
          content: TextField(
            controller: controller,
            maxLength: 300,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Escribe tu comentario',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();

                if (text.isEmpty) return;

                Navigator.of(context).pop(text);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (updatedText == null || updatedText.isEmpty) return;

    try {
      final updated = await _dataSource.updateComment(
        commentId: comment.id,
        comment: updatedText,
      );

      if (!mounted) return;

      setState(() {
        _comments = _comments
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _toggleExpanded,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
          label: Text(
            _isExpanded
                ? 'Ocultar comentarios'
                : _commentsCount == 1
                    ? 'Ver 1 comentario'
                    : 'Ver $_commentsCount comentarios',
          ),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF003B73),
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          _CommentInput(
            controller: _commentController,
            isSubmitting: _isSubmitting,
            onSubmit: _submitComment,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_comments.isEmpty)
            const Text(
              'Sé el primero en comentar esta reseña.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
              ),
            )
          else
            ..._comments.map(
              (comment) => _CommentTile(
                comment: comment,
                onEdit: () => _editComment(comment),
                onDelete: () => _deleteComment(comment),
              ),
            ),
        ],
      ],
    );
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            maxLength: 300,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Responder a esta reseña...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFD1D5DB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFD1D5DB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF003B73),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 46,
          width: 46,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: const Color(0xFF003B73),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 19),
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onEdit,
    required this.onDelete,
  });

  final ReviewCommentModel comment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: const Color(0xFFE0ECF7),
                child: Text(
                  comment.userName.trim().isEmpty
                      ? 'U'
                      : comment.userName.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF003B73),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.userName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (comment.isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.comment,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}