import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ChatPageDetails.dart';

const Color appGreen = Color(0xFF087A55);

class MemberProfilePage extends StatelessWidget {
  final String userId;

  const MemberProfilePage({
    super.key,
    required this.userId,
  });

  Future<void> _openChat(
    BuildContext context,
    Map<String, dynamic> member,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('आधी login करा.')),
      );
      return;
    }

    final memberUid = (member['uid'] ?? userId).toString();
    final memberName = (member['name'] ?? 'Krushi member').toString();

    if (memberUid == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('तुम्ही स्वतःसोबत chat करू शकत नाही.')),
      );
      return;
    }

    // दोन्ही users साठी एकच chat ID तयार होईल.
    final participants = [currentUser.uid, memberUid]..sort();
    final chatId = participants.join('_');

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

    try {

      final currentUserDoc = await FirebaseFirestore.instance
      .collection('user')
      .doc(currentUser.uid)
      .get();

       final currentUserName =
      currentUserDoc.data()?['name']?.toString() ??
      currentUser.displayName ??
      'Krushi member';

      await chatRef.set({
        'participants': participants,
        'memberNames': {
          currentUser.uid: currentUserName,
          memberUid: memberName,
        },
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailsPage(
            chatId: chatId,
            otherUserId: memberUid,
            otherUserName: memberName,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat उघडता आला नाही: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appGreen,
        foregroundColor: Colors.white,
        title: const Text('Member Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future:
            FirebaseFirestore.instance.collection('user').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Profile लोड करता आला नाही.'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Member सापडला नाही.'));
          }

          final member = snapshot.data!.data()!;
          final name = (member['name'] ?? 'Krushi member').toString();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFFD9EEE5),
                child: Text(
                  name.isEmpty ? 'K' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: appGreen,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _info('Email', member['email']),
              _info('Mobile', member['mobile']),
              _info('Shop', member['shop']),
              _info('Location', member['location']),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _openChat(context, member),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(String label, dynamic value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.black54)),
      subtitle: Text((value ?? '-').toString()),
    );
  }
}