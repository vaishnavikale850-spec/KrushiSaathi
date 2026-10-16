import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DiscussionDetailsPage extends StatefulWidget {
  const DiscussionDetailsPage({
    super.key,
    required this.discussionId,
  });

  final String discussionId;

  @override
  State<DiscussionDetailsPage> createState() =>
      _DiscussionDetailsPageState();
}

class _DiscussionDetailsPageState extends State<DiscussionDetailsPage> {
  static const Color green = Color(0xFF087A55);

  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  String? _replyToCommentId;
  String? _replyToName;

  DocumentReference<Map<String, dynamic>> get _discussionRef =>
      FirebaseFirestore.instance
          .collection('discussions')
          .doc(widget.discussionId);

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) return 'Just now';

    final elapsed = DateTime.now().difference(value.toDate());

    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    return '${elapsed.inDays}d ago';
  }

  void _startReply(String commentId, String name) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToName = name;
    });

    _replyFocusNode.requestFocus();
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in to like this discussion.');
      return;
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(_discussionRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() ?? <String, dynamic>{};
        final likedBy = data['likedBy'] is List
            ? List<String>.from(data['likedBy'])
            : <String>[];
        final alreadyLiked = likedBy.contains(user.uid);

        transaction.update(_discussionRef, {
          'likes': FieldValue.increment(alreadyLiked ? -1 : 1),
          'likedBy': alreadyLiked
              ? FieldValue.arrayRemove([user.uid])
              : FieldValue.arrayUnion([user.uid]),
        });
      });
    } catch (error) {
      _showMessage('Could not update like: $error');
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (text.isEmpty) return;

    if (user == null) {
      _showMessage('Please log in to reply.');
      return;
    }

    try {
      final commentRef = _discussionRef.collection('comments').doc();
      final batch = FirebaseFirestore.instance.batch();

      batch.set(commentRef, {
        'text': text,
        'authorId': user.uid,
        'authorName': user.displayName ?? user.email ?? 'Krushi member',
        'createdAt': FieldValue.serverTimestamp(),
        'replyToCommentId': _replyToCommentId,
        'replyToName': _replyToName,
      });

      batch.update(_discussionRef, {
        'commentsCount': FieldValue.increment(1),
      });

      await batch.commit();

      if (!mounted) return;

      _replyController.clear();
      setState(() {
        _replyToCommentId = null;
        _replyToName = null;
      });

      _showMessage('Reply sent.');
    } catch (error) {
      _showMessage('Could not send reply: $error');
    }
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToName = null;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF26382E),
        elevation: 0,
        title: const Text(
          'Discussion Details',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _discussionRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load discussion.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: green),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Discussion not found.'));
          }

          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final imageUrl = data['imageUrl'] as String?;
          final authorName =
              data['authorName'] as String? ?? 'Krushi member';
          final userId = FirebaseAuth.instance.currentUser?.uid;
          final likedBy = data['likedBy'] is List
              ? List<String>.from(data['likedBy'])
              : <String>[];
          final isLiked = userId != null && likedBy.contains(userId);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 170,
                              color: const Color(0xFFE9EFEA),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    _authorRow(
                      authorName,
                      _formatTime(data['createdAt']),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['title'] as String? ?? 'Untitled discussion',
                      style: const TextStyle(
                        color: Color(0xFF26382E),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        InkWell(
                          onTap: _toggleLike,
                          borderRadius: BorderRadius.circular(18),
                          child: Row(
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.redAccent,
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text('${data['likes'] ?? 0}'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.blueGrey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text('${data['commentsCount'] ?? 0}'),
                        const Spacer(),
                        _categoryTag(
                          data['category'] as String? ?? 'General',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF26382E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['description'] as String? ?? '',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Discussion',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF26382E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _commentsList(),
                  ],
                ),
              ),
              _replyInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _authorRow(String name, String time) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'K';

    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: const Color(0xFFD9EEE5),
          child: Text(
            initial,
            style: const TextStyle(
              color: green,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 9, color: Colors.black45),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryTag(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F2E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: green,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _commentsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _discussionRef
          .collection('comments')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Could not load replies.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final comments = snapshot.data?.docs ?? [];

        if (comments.isEmpty) {
          return const Text(
            'No replies yet. Share your advice!',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          );
        }

        return Column(
          children: comments.map((comment) {
            final data = comment.data();
            final name =
                data['authorName'] as String? ?? 'Krushi member';

            return _commentTile(
              name: name,
              text: data['text'] as String? ?? '',
              time: _formatTime(data['createdAt']),
              replyToName: data['replyToName'] as String?,
              onReply: () => _startReply(comment.id, name),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _commentTile({
    required String name,
    required String text,
    required String time,
    required VoidCallback onReply,
    String? replyToName,
  }) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'K';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFD9EEE5),
            child: Text(
              initial,
              style: const TextStyle(
                color: green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                if (replyToName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '↳ Replying to $replyToName',
                    style: const TextStyle(
                      color: green,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(fontSize: 12)),
                InkWell(
                  onTap: onReply,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Reply',
                      style: TextStyle(
                        color: green,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _replyInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyToName != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to $_replyToName',
                      style: const TextStyle(
                        color: green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _cancelReply,
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    focusNode: _replyFocusNode,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: _replyToName == null
                          ? 'Write a reply...'
                          : 'Replying to $_replyToName...',
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF3F6F3),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendReply,
                  style: IconButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}