import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:krushi/CommunityMembersPage.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  static const Color green = Color(0xFF087A55);

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _updatingCommunities = {};

  final List<String> _categories = const [
    'All',
    'Crop',
    'Product',
    'Region',
  ];

  String _searchText = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleJoin(String communityId) async {
    // Prevent another tap while this community's request is in progress.
    if (_updatingCommunities.contains(communityId)) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in to join a community.');
      return;
    }

    setState(() => _updatingCommunities.add(communityId));

    final communityRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(communityRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() ?? <String, dynamic>{};
        final memberIds = data['memberIds'] is List
            ? List<String>.from(data['memberIds'])
            : <String>[];

        if (memberIds.contains(user.uid)) {
          memberIds.remove(user.uid);
        } else {
          memberIds.add(user.uid);
        }

        transaction.update(communityRef, {
          'memberIds': memberIds,
          'members': memberIds.length,
        });
      });
    } catch (e) {
      _showMessage('Could not update the community: $e');
    } finally {
      if (mounted) {
        setState(() => _updatingCommunities.remove(communityId));
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatMemberCount(dynamic value) {
    final count = value is num ? value.toInt() : 0;

    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Community',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildCategoryFilters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('communities')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load communities.'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: green),
                  );
                }

                final communities = (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data();

                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final category =
                      (data['category'] ?? '').toString().toLowerCase();
                  final region =
                      (data['region'] ?? '').toString().toLowerCase();

                  final matchesSearch = name.contains(_searchText) ||
                      category.contains(_searchText) ||
                      region.contains(_searchText);

                  final matchesCategory = _selectedCategory == 'All' ||
                      category == _selectedCategory.toLowerCase();

                  return matchesSearch && matchesCategory;
                }).toList();

                if (communities.isEmpty) {
                  return Center(
                    child: Text(
                      _searchText.isEmpty && _selectedCategory == 'All'
                          ? 'No communities have been created yet.'
                          : 'No communities found.',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 5, 12, 16),
                  itemCount: communities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final doc = communities[index];
                    final data = doc.data();

                    final memberIds = data['memberIds'] is List
                        ? List<String>.from(data['memberIds'])
                        : <String>[];

                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    final isMember =
                        userId != null && memberIds.contains(userId);

                    final memberCount = data['members'] ?? memberIds.length;

                    return _communityCard(
                      id: doc.id,
                      name: data['name'] as String? ?? 'Community',
                      region: data['region'] as String? ?? '',
                      members: _formatMemberCount(memberCount),
                      imageUrl: data['imageUrl'] as String?,
                      memberIds: memberIds,
                      isMember: isMember,
                      isUpdating: _updatingCommunities.contains(doc.id),
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

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchText = value.trim().toLowerCase());
        },
        decoration: InputDecoration(
          hintText: 'Search communities...',
          prefixIcon: const Icon(Icons.search, color: green, size: 20),
          suffixIcon: _searchText.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchText = '');
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedCategory = category);
            },
            selectedColor: green,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF53665B),
              fontSize: 11,
            ),
            side: BorderSide(
              color: selected ? green : const Color(0xFFE1E8E2),
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _communityCard({
    required String id,
    required String name,
    required String region,
    required String members,
    required String? imageUrl,
    required List<String> memberIds,
    required bool isMember,
    required bool isUpdating,
  }) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE5EBE6)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _communityPlaceholder(),
                  )
                : _communityPlaceholder(),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF26382E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  region.isEmpty
                      ? '$members members'
                      : '$region • $members members',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'View members',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 34,
              minHeight: 34,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommunityMembersPage(
                    communityName: name,
                    memberIds: memberIds,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.people_outline,
              size: 20,
              color: green,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 30,
            child: ElevatedButton(
              onPressed: isUpdating ? null : () => _toggleJoin(id),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isMember ? const Color(0xFFE8F2EB) : green,
                foregroundColor: isMember ? green : Colors.white,
                disabledBackgroundColor: const Color(0xFFE8F2EB),
                disabledForegroundColor: green,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isUpdating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: green,
                      ),
                    )
                  : Text(
                      isMember ? 'Following' : 'Join',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: const Color(0xFFE5F0E6),
      alignment: Alignment.center,
      child: const Icon(Icons.groups_rounded, color: green),
    );
  }
}