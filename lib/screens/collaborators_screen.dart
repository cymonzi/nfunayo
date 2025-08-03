// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/error_handler.dart';

class CollaboratorsScreen extends StatefulWidget {
  const CollaboratorsScreen({super.key});

  @override
  State<CollaboratorsScreen> createState() => _CollaboratorsScreenState();
}

class _CollaboratorsScreenState extends State<CollaboratorsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  
  List<Map<String, dynamic>> _myGroups = [];
  List<Map<String, dynamic>> _invitations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _loadGroupsAndInvitations();
  }

  void _checkAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('=== Authentication Check ===');
    debugPrint('Current user: ${user?.email}');
    debugPrint('User UID: ${user?.uid}');
    debugPrint('User display name: ${user?.displayName}');
    debugPrint('User is anonymous: ${user?.isAnonymous}');
    debugPrint('User email verified: ${user?.emailVerified}');
    debugPrint('================================');
  }

  Future<void> _loadGroupsAndInvitations() async {
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No authenticated user found');
      setState(() => _isLoading = false);
      return;
    }

    debugPrint('Current user: ${user.email}, UID: ${user.uid}');

    try {
      // Load groups where user is owner or member
      debugPrint('Querying expense_groups for user: ${user.email}');
      final groupsQuery = await _firestore
          .collection('expense_groups')
          .where('members', arrayContains: user.email)
          .get();

      debugPrint('Found ${groupsQuery.docs.length} groups');
      
      final groups = groupsQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      // Load pending invitations
      debugPrint('Querying invitations for user: ${user.email}');
      final invitationsQuery = await _firestore
          .collection('invitations')
          .where('inviteeEmail', isEqualTo: user.email)
          .where('status', isEqualTo: 'pending')
          .get();

      debugPrint('Found ${invitationsQuery.docs.length} invitations');

      final invitations = invitationsQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      setState(() {
        _myGroups = groups;
        _invitations = invitations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading data: $e');
      ErrorHandler.showErrorSnackBar(
        context,
        'Error loading data: ${e.toString()}'
      );
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Please enter a group name'
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('expense_groups').add({
        'name': _groupNameController.text.trim(),
        'owner': user.email,
        'members': [user.email],
        'createdAt': FieldValue.serverTimestamp(),
        'totalExpenses': 0.0,
        'currency': 'UGX',
      });

      _groupNameController.clear();
      _loadGroupsAndInvitations();
      Navigator.pop(context);
      
      ErrorHandler.showSuccessSnackBar(
        context,
        'Group created successfully!'
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Error creating group: ${e.toString()}'
      );
    }
  }

  Future<void> _inviteUser(String groupId, String groupName) async {
    if (_emailController.text.trim().isEmpty) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Please enter an email address'
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final inviteeEmail = _emailController.text.trim();
      await _firestore.collection('invitations').add({
        'groupId': groupId,
        'groupName': groupName,
        'inviterEmail': user.email,
        'inviterName': user.displayName ?? user.email,
        'inviteeEmail': inviteeEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _emailController.clear();
      Navigator.pop(context);

      ErrorHandler.showSuccessSnackBar(
        context,
        "Invite sent! We've let $inviteeEmail know you want to share expenses together. You'll see them here when they join."
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Error sending invitation: ${e.toString()}'
      );
    }
  }

  Future<void> _respondToInvitation(String invitationId, String groupId, bool accept) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (accept) {
        // Add user to group members
        await _firestore.collection('expense_groups').doc(groupId).update({
          'members': FieldValue.arrayUnion([user.email]),
        });
      }

      // Update invitation status
      await _firestore.collection('invitations').doc(invitationId).update({
        'status': accept ? 'accepted' : 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      _loadGroupsAndInvitations();
      
      ErrorHandler.showSuccessSnackBar(
        context,
        accept ? 'Invitation accepted!' : 'Invitation declined'
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Error responding to invitation: ${e.toString()}'
      );
    }
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: _groupNameController,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            hintText: 'e.g., Family Expenses, Trip to Kampala',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _createGroup,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invite to $groupName'),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'friend@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _inviteUser(groupId, groupName),
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaborators'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGroupsAndInvitations,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pending Invitations Section
                    if (_invitations.isNotEmpty) ...[
                      const Text(
                        'Pending Invitations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(_invitations.map((invitation) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.mail, color: Colors.white),
                          ),
                          title: Text(invitation['groupName']),
                          subtitle: Text('Invited by ${invitation['inviterName']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _respondToInvitation(
                                  invitation['id'],
                                  invitation['groupId'],
                                  false,
                                ),
                                icon: const Icon(Icons.close, color: Colors.red),
                              ),
                              IconButton(
                                onPressed: () => _respondToInvitation(
                                  invitation['id'],
                                  invitation['groupId'],
                                  true,
                                ),
                                icon: const Icon(Icons.check, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      )).toList()),
                      const SizedBox(height: 24),
                    ],

                    // My Groups Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Groups',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showCreateGroupDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Group'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_myGroups.isEmpty)
                      const Center(
                        child: Column(
                          children: [
                            SizedBox(height: 40),
                            Icon(Icons.group, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No groups yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create a group to start sharing expenses',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      ...(_myGroups.map((group) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              group['name'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(group['name']),
                          subtitle: Text(
                            '${group['members'].length} members • UGX ${group['totalExpenses'].toStringAsFixed(0)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showInviteDialog(
                                  group['id'],
                                  group['name'],
                                ),
                                icon: const Icon(Icons.person_add),
                                tooltip: 'Invite Member',
                              ),
                              IconButton(
                                onPressed: () {
                                  // TODO: Navigate to group details/transactions
                                },
                                icon: const Icon(Icons.arrow_forward_ios),
                              ),
                            ],
                          ),
                        ),
                      )).toList()),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }
}
