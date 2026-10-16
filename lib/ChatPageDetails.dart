import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color detailsGreen = Color(0xFF087A55);

class ChatDetailsPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatDetailsPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final sender = FirebaseAuth.instance.currentUser;
    final text = _messageController.text.trim();

    if (sender == null || text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(sender.uid)
          .get();

      final senderName =
          userDoc.data()?['name']?.toString() ??
          sender.displayName ??
          'Krushi member';

      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId);

      // Save message in the chat.
      await chatRef.collection('messages').add({
        'senderId': sender.uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the last message shown in ChatPage.
      await chatRef.set({
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Save a notification for the other member.
      await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.otherUserId)
          .collection('notifications')
          .add({
            'title': 'New Message',
            'message': text,
            'type': 'message',
            'actorName': sender.displayName ?? sender.email ?? 'Krushi member',
            'senderId': sender.uid,
            'chatId': widget.chatId,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not send message: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('To see chats please login.')),
      );
    }

    final messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: detailsGreen,
        foregroundColor: Colors.white,
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Messages will not have sent.'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('please send message to start chat.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final isMine = data['senderId'] == currentUser.uid;
                    final senderId = (data['senderId'] ?? '').toString();

                    final senderName = isMine ? 'You' : widget.otherUserName;
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                        ),
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? detailsGreen
                              : const Color(0xFFE8F1EC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (data['text'] ?? '').toString(),
                              style: TextStyle(
                                color: isMine ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['createdAt'] != null
                                  ? DateFormat('hh:mm a').format(
                                      (data['createdAt'] as Timestamp).toDate(),
                                    )
                                  : 'Sending...',
                              style: TextStyle(
                                color: isMine ? Colors.white70 : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        filled: true,
                        fillColor: const Color(0xFFF1F4F2),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: detailsGreen,
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 19,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
