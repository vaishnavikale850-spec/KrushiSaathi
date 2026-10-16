import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:krushi/Login.dart';
import 'package:krushi/UserSectionPage.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color green = Color(0xFF087A55);

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (_)=>Login()));
    if (!context.mounted) return;

    // तुमच्या Login page कडे navigate करण्यासाठी code इथे जोडा.
    _showMessage(context, 'Logged out successfully.');
  }

  void _openUserSection(BuildContext context, String userId, String section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserSectionPage(userId: userId, section: section),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const Scaffold(
      body: Center(child: Text('Please log in to view your profile.')),
    );
  }

  final userId = user.uid;

  final profileStream = FirebaseFirestore.instance
      .collection('user')
      .doc(userId)
      .snapshots();

  final discussionsQuery = FirebaseFirestore.instance
      .collection('discussions')
      .where('authorId', isEqualTo: userId);

  final joinedCommunitiesQuery = FirebaseFirestore.instance
      .collection('communities')
      .where('memberIds', arrayContains: userId);

  final repliesQuery = FirebaseFirestore.instance
    .collectionGroup('comments')
    .where('authorId', isEqualTo: user.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _showMessage(context, 'Settings page'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: profileStream,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.hasError) {
            return const Center(child: Text('Could not load your profile.'));
          }

          if (!profileSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = profileSnapshot.data!.data() ?? {};
          final name = (profile['name'] ?? 'Krushi Member').toString();
          final shop = (profile['shop'] ?? 'Shopkeeper').toString();
          final email = (profile['email'] ?? user.email ?? '').toString();
          final location = (profile['location'] ?? '').toString();
          final photoUrl = (profile['photoUrl'] ?? '').toString();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _profileHeader(
                name: name,
                shop: shop,
                email: email,
                location: location,
                photoUrl: photoUrl,
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _liveCountCard(
                      title: 'Discussions',
                      query: discussionsQuery,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _liveCountCard(
                      title: 'Communities',
                      query: joinedCommunitiesQuery,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _liveCountCard(
                      title: 'Replies',
                      query: repliesQuery,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'My Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF26382E),
                ),
              ),
              const SizedBox(height: 8),

              _menuTile(
                icon: Icons.forum_outlined,
                title: 'My Discussions',
                onTap: () => _openUserSection(context, userId, 'discussions'),
              ),
              _menuTile(
                icon: Icons.reply_outlined,
                title: 'My Replies',
                onTap: () => _openUserSection(context, userId, 'replies'),
              ),
              _menuTile(
                icon: Icons.groups_outlined,
                title: 'My Communities',
                onTap: () => _openUserSection(context, userId, 'communities'),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _profileHeader({
    required String name,
    required String shop,
    required String email,
    required String location,
    required String photoUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EBE6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFD9EEE5),
            foregroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl.isEmpty
                ? Text(
                    name.isEmpty ? 'K' : name[0].toUpperCase(),
                    style: const TextStyle(
                      color: green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF26382E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(shop, style: const TextStyle(fontSize: 12)),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                if (location.isNotEmpty)
                  Text(
                    location,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveCountCard({
    required String title,
    required Query<Map<String, dynamic>> query,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE5EBE6)),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;

          return Column(
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE9EEEA)),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20, color: green),
        title: Text(title, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }
}
