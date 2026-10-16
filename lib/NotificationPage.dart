import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  
  static const Color _green = Color(0xFF087A55);

  IconData _iconFor(String type) {
    switch (type) {
      case 'reply':
        return Icons.chat_bubble_outline;
      case 'member':
        return Icons.person_add_alt_1;
      case 'like':
        return Icons.favorite_outline;
      case 'message':
        return Icons.mail_outline;
      case 'community':
        return Icons.groups_outlined;
      case 'saved':
        return Icons.bookmark_border;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'reply':
        return Colors.orange;
      case 'member':
        return Colors.blue;
      case 'like':
        return Colors.redAccent;
      case 'message':
        return Colors.lightBlue;
      case 'community':
        return _green;
      case 'saved':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }

  String _timeAgo(dynamic value) {
    if (value is! Timestamp) return 'Just now';

    final date = value.toDate();
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _markAsRead(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    await reference.update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications.')),
      );
    }

    final notificationStream = FirebaseFirestore.instance
        .collection('user')
        .doc(user.uid)
        .collection('notifications')
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load notifications: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _green),
            );
          }

          final notifications = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aTime = a.data()['createdAt'];
              final bTime = b.data()['createdAt'];
              final aDate =
                  aTime is Timestamp ? aTime.toDate() : DateTime(2000);
              final bDate =
                  bTime is Timestamp ? bTime.toDate() : DateTime(2000);
              return bDate.compareTo(aDate);
            });

          if (notifications.isEmpty) {
            return const Center(
              child: Text('You have no notifications yet.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 62,
              endIndent: 12,
            ),
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data();

              final type = (data['type'] ?? '').toString();
              final title = (data['title'] ?? 'Notification').toString();
              final message = (data['message'] ?? '').toString();
              final actorName = (data['actorName'] ?? '').toString();
              final isRead = data['isRead'] == true;

              return ListTile(
                tileColor: isRead ? null : const Color(0xFFEFF7F1),
                leading: CircleAvatar(
                  radius: 19,
                  backgroundColor: _colorFor(type).withValues(alpha: 0.12),
                  child: Icon(
                    _iconFor(type),
                    color: _colorFor(type),
                    size: 19,
                  ),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  actorName.isEmpty ? message : '$actorName: $message',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  _timeAgo(data['createdAt']),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black45,
                  ),
                ),
                onTap: () async {
                  if (!isRead) {
                    await _markAsRead(doc.reference);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}