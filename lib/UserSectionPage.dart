import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSectionPage extends StatelessWidget {
  final String userId;
  final String section;

  const UserSectionPage({
    super.key,
    required this.userId,
    required this.section,
  });

  String get _title {
    switch (section) {
      case 'discussions':
        return 'My Discussions';
      case 'replies':
        return 'My Replies';
      default:
        return 'My Communities';
    }
  }

  Query<Map<String, dynamic>> _query() {
    switch (section) {
      case 'discussions':
        return FirebaseFirestore.instance
            .collection('discussions')
            .where('authorId', isEqualTo: userId);

      case 'replies':
        return FirebaseFirestore.instance
            .collectionGroup('comments')
            .where('authorId', isEqualTo: userId);

      default:
        return FirebaseFirestore.instance
            .collection('communities')
            .where('memberIds', arrayContains: userId);
    }
  }

  String _itemTitle(Map<String, dynamic> data) {
    if (section == 'replies') {
      return (data['text'] ?? 'Reply').toString();
    }

    return (data['title'] ?? data['name'] ?? 'Untitled').toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF087A55),
        foregroundColor: Colors.white,
        title: Text(_title),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load data.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Text('No ${_title.toLowerCase()} yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              return ListTile(
                leading: Icon(
                  section == 'discussions'
                      ? Icons.forum_outlined
                      : section == 'replies'
                          ? Icons.reply_outlined
                          : Icons.groups_outlined,
                  color: const Color(0xFF087A55),
                ),
                title: Text(_itemTitle(data)),
                subtitle: Text(
                  (data['description'] ??
                          data['category'] ??
                          data['name'] ??
                          '')
                      .toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
        },
      ),
    );
  }
}