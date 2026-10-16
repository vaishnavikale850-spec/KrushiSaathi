import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ChatPageDetails.dart';

const Color chatGreen = Color(0xFF087A55);

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) return '';

    final difference = DateTime.now().difference(value.toDate());

    if (difference.inMinutes < 1) return 'Now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('To see the chat please login')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: chatGreen,
        foregroundColor: Colors.white,
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('loading Chats.'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final aValue = a.data()['updatedAt'];
                    final bValue = b.data()['updatedAt'];
                    final aDate =
                        aValue is Timestamp ? aValue.toDate() : DateTime(2000);
                    final bDate =
                        bValue is Timestamp ? bValue.toDate() : DateTime(2000);
                    return bDate.compareTo(aDate);
                  });

                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final participants =
                      List<String>.from(data['participants'] ?? []);
                  final otherUid = participants.firstWhere(
                    (id) => id != currentUser.uid,
                    orElse: () => '',
                  );

                  final names =
                      Map<String, dynamic>.from(data['memberNames'] ?? {});
                  final name =
                      (names[otherUid] ?? 'Krushi member').toString();
                  final message = (data['lastMessage'] ?? '').toString();

                  return name.toLowerCase().contains(_searchQuery) ||
                      message.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No chats available. please message.'
                          : 'No chats Found.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    final participants =
                        List<String>.from(data['participants'] ?? []);
                    final otherUid = participants.firstWhere(
                      (id) => id != currentUser.uid,
                      orElse: () => '',
                    );

                    final names =
                        Map<String, dynamic>.from(data['memberNames'] ?? {});
                    final name =
                        (names[otherUid] ?? 'Krushi member').toString();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFD9EEE5),
                        child: Text(
                          name.isEmpty ? 'K' : name[0].toUpperCase(),
                          style: const TextStyle(
                            color: chatGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        (data['lastMessage'] ?? 'Start a conversation')
                            .toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatTime(data['updatedAt']),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailsPage(
                              chatId: doc.id,
                              otherUserId: otherUid,
                              otherUserName: name,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}