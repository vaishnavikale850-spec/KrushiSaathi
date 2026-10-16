import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:krushi/DiscussionDetailsPage.dart';
import 'package:krushi/NotificationPage.dart';
import 'package:krushi/NotoficationCount.dart';
import 'package:krushi/RaiseProblemPage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const Color green = Color(0xFF087A55);
  static const Color background = Color(0xFFF4F7F3);

  final TextEditingController searchController = TextEditingController();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _discussionsStream;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();

    _discussionsStream = FirebaseFirestore.instance
        .collection('discussions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    searchController.dispose();
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

  Future<void> _toggleLike(String docId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Like करण्यासाठी login करा.')),
      );
      return;
    }

    final discussionRef = FirebaseFirestore.instance
        .collection('discussions')
        .doc(docId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(discussionRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() ?? <String, dynamic>{};

        final likedBy = data['likedBy'] is List
            ? List<String>.from(data['likedBy'])
            : <String>[];

        final alreadyLiked = likedBy.contains(user.uid);

        transaction.update(discussionRef, {
          'likes': FieldValue.increment(alreadyLiked ? -1 : 1),
          'likedBy': alreadyLiked
              ? FieldValue.arrayRemove([user.uid])
              : FieldValue.arrayUnion([user.uid]),
        });
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Like update झाले नाही: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _discussionsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Could not load discussions.'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: green),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final filteredDocs = docs.where((doc) {
                    final data = doc.data();

                    final searchableText =
                        [
                              data['title'],
                              data['description'],
                              data['cropName'],
                              data['category'],
                              data['authorName'],
                              data['email'],
                            ]
                            .where((value) => value != null)
                            .map((value) => value.toString())
                            .join(' ')
                            .toLowerCase();

                    return searchableText.contains(searchQuery);
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                    children: [
                      _buildSearch(),
                      const SizedBox(height: 12),
                      _buildBanner(),
                      const SizedBox(height: 10),
                      _buildRaiseProblemButton(),
                      const SizedBox(height: 12),
                      _buildSectionTitle(),
                      const SizedBox(height: 8),
                      if (filteredDocs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              searchQuery.isEmpty
                                  ? 'No discussions yet.'
                                  : 'No discussions found for this search.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...filteredDocs.map((doc) {
                          final data = doc.data();
                          final author =
                              data['authorName'] as String? ?? 'Krushi member';

                          final words = author
                              .trim()
                              .split(RegExp(r'\s+'))
                              .where((word) => word.isNotEmpty)
                              .toList();

                          final initials = words
                              .take(2)
                              .map((word) => word[0].toUpperCase())
                              .join();

                          final likedBy = data['likedBy'] is List
                              ? List<String>.from(data['likedBy'])
                              : <String>[];

                          final currentUserId =
                              FirebaseAuth.instance.currentUser?.uid;
                          final isLiked =
                              currentUserId != null &&
                              likedBy.contains(currentUserId);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _discussionCard(
                              docId: doc.id,
                              isLiked: isLiked,
                              initials: initials.isEmpty ? 'K' : initials,
                              name: author,
                              time: _formatTime(data['createdAt']),
                              title:
                                  data['title'] as String? ??
                                  'Untitled discussion',
                              description: data['description'] as String? ?? '',
                              imageUrl: data['imageUrl'] as String?,
                              likes: '${data['likes'] ?? 0}',
                              comments: '${data['commentsCount'] ?? 0}',
                              tag: data['category'] as String? ?? 'General',
                              color: green,
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 9, 14, 8),
      color: Colors.white,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE4F2E8),
            child: Icon(Icons.eco, color: green, size: 20),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KrushiMitra',
                  style: TextStyle(
                    color: green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Shopkeeper Community',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
          NotificationBadge(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: searchController,
      onChanged: (value) {
        setState(() {
          searchQuery = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search discussions...',
        hintStyle: const TextStyle(fontSize: 12, color: Colors.black45),
        prefixIcon: const Icon(Icons.search, size: 19, color: green),
        suffixIcon: searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  searchController.clear();
                  setState(() => searchQuery = '');
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF174D39), Color(0xFF5B9C53)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 4,
            bottom: 0,
            child: Icon(
              Icons.agriculture_rounded,
              size: 58,
              color: Color(0x66FFFFFF),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Better Advice\nBetter Business',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.15,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              const Spacer(),
              Text(
                'Share  •  Learn  •  Grow',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRaiseProblemButton() {
    return SizedBox(
      height: 38,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RaiseProblemPage()),
          );
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text(
          'Raise Problem',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Discussions',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF26382E),
          ),
        ),
      ],
    );
  }

  Widget _discussionCard({
    required String docId,
    required bool isLiked,
    required String initials,
    required String name,
    required String time,
    required String title,
    required String description,
    String? imageUrl,
    required String likes,
    required String comments,
    required String tag,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 9, color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF26382E),
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;

                    return const SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(color: green),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      width: double.infinity,
                      color: const Color(0xFFF1F4F1),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 9),
            Row(
              children: [
                InkWell(
                  onTap: () => _toggleLike(docId),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isLiked ? Colors.redAccent : Colors.blueGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(likes, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DiscussionDetailsPage(discussionId: docId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 13,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(width: 4),
                Text(comments, style: const TextStyle(fontSize: 10)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: green,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
