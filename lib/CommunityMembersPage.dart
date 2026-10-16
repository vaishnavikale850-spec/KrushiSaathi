import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'MemberProfile.dart';

class CommunityMembersPage extends StatelessWidget {
  final String communityName;
  final List<String> memberIds;

  const CommunityMembersPage({
    super.key,
    required this.communityName,
    required this.memberIds,
  });

  static const Color _green = Color(0xFF087A55);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: Text('$communityName Members'),
      ),
      body: memberIds.isEmpty
          ? const Center(
              child: Text('In this community has not members.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: memberIds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final uid = memberIds[index];

                return FutureBuilder<
                    DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('user')
                      .doc(uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const SizedBox.shrink();
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          title: Text('Loading Member...'),
                        ),
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    final member = snapshot.data!.data()!;
                    final name =
                        (member['name'] ?? 'Krushi member').toString();
                    final shop =
                        (member['shop'] ?? member['location'] ?? '')
                            .toString();

                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: const BorderSide(color: Color(0xFFE5EBE6)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFD9EEE5),
                          child: Text(
                            name.isEmpty ? 'M' : name[0].toUpperCase(),
                            style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: shop.isEmpty ? null : Text(shop),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: _green,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MemberProfilePage(
                                userId: uid,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}