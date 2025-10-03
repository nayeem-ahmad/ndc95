import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'user_detail_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => DirectoryScreenState();
}

class DirectoryScreenState extends State<DirectoryScreen> {
  static const List<String> _groupOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGroup; // null means "All"

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void applyGroupFilter(String? group) {
    setState(() {
      _selectedGroup = group;
      _searchQuery = '';
      _searchController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Container(height: 1, color: Colors.grey.shade200),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error);
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.people_outline,
                  title: 'No users found',
                  subtitle: 'Be the first to register!',
                );
              }

              final filteredUsers = _filterAndSortUsers(snapshot.data!.docs);

              if (filteredUsers.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.search_off,
                  title: 'No results found',
                  subtitle: 'Try a different search term',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCountBadge(filteredUsers.length),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final doc = filteredUsers[index];
                        final userData = doc.data() as Map<String, dynamic>;
                        return _buildUserRow(
                          userId: doc.id,
                          displayName: userData['displayName'] ?? 'No Name',
                          email: userData['email'] ?? 'No Email',
                          phoneNumber: userData['phoneNumber'] ?? 'No Phone',
                          photoUrl: userData['photoUrl'],
                          nickName: userData['nickName'],
                          studentId: userData['studentId'],
                          group: userData['group']?.toString(),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 12),
          _buildGroupDropdown(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search name, email, or phone',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildGroupDropdown() {
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String?>(
        key: ValueKey(_selectedGroup),
        initialValue: _selectedGroup,
        decoration: InputDecoration(
          labelText: 'Group',
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All groups'),
          ),
          ..._groupOptions.map(
            (group) => DropdownMenuItem<String?>(
              value: group,
              child: Text('Group $group'),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedGroup = value;
          });
        },
      ),
    );
  }

  List<QueryDocumentSnapshot<Object?>> _filterAndSortUsers(
    List<QueryDocumentSnapshot<Object?>> docs,
  ) {
    final filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      if (_selectedGroup != null) {
        final userGroupRaw = data['group'];
        final userGroup = userGroupRaw?.toString().trim() ?? '';
        if (userGroup.isEmpty || userGroup != _selectedGroup) {
          return false;
        }
      }

      if (_searchQuery.isEmpty) {
        return true;
      }

      final name = (data['displayName'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final phone = (data['phoneNumber'] ?? '').toString().toLowerCase();

      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          phone.contains(_searchQuery);
    }).toList();

    filtered.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final studentIdA = dataA['studentId']?.toString() ?? '';
      final studentIdB = dataB['studentId']?.toString() ?? '';

      if (studentIdA.isEmpty && studentIdB.isEmpty) return 0;
      if (studentIdA.isEmpty) return 1;
      if (studentIdB.isEmpty) return -1;

      return studentIdA.compareTo(studentIdB);
    });

    return filtered;
  }

  Widget _buildCountBadge(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 18,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            '$count ${count == 1 ? 'contact' : 'contacts'}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          if (_selectedGroup != null || _searchQuery.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              'found',
              style: TextStyle(
                color: Colors.blue.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserRow({
    required String userId,
    required String displayName,
    required String email,
    required String phoneNumber,
    String? photoUrl,
    String? nickName,
    String? studentId,
    String? group,
  }) {
    final currentUserId = FirebaseService.currentUser?.uid;
    final isCurrentUser = userId == currentUserId;

    return InkWell(
      onTap: () async {
        final userDoc = await FirebaseService.getUserProfile(userId);
        if (userDoc.exists && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(
                userId: userId,
                userData: userDoc.data() as Map<String, dynamic>,
              ),
            ),
          );
        }
      },
      child: Padding(
  padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (photoUrl != null && photoUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(photoUrl),
                    backgroundColor: Colors.blue.shade100,
                  )
                else
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                if (nickName != null && nickName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      nickName,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (group != null && group.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Group $group',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (isCurrentUser)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 14,
                    runSpacing: 2,
                    children: [
                      _buildInfoChip(Icons.email_outlined, email),
                      _buildInfoChip(Icons.phone_outlined, phoneNumber),
                      if (studentId != null && studentId.isNotEmpty)
                        _buildInfoChip(Icons.badge_outlined, studentId),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading users',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Make sure Firestore API is enabled in Firebase Console',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
