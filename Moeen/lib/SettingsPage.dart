import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final gold = const Color(0xFFD4AF37);
  final black = const Color(0xFF0B0F19);
  final black2 = const Color(0xFF141927);

  late Future<Map<String, dynamic>> _userData;

  @override
  void initState() {
    super.initState();
    _userData = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final doc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      return {
        'username': user.displayName ?? '—',
        'email': user.email ?? '—',
      };
    }

    final data = doc.data()!;
    return {
      'username': data['username'] ?? user.displayName ?? '—',
      'email': data['email'] ?? user.email ?? '—',
    };
  }

  Future<void> _editUsername(String currentUsername) async {
    final controller = TextEditingController(text: currentUsername);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: black2,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Edit Username',
              style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter new username',
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: gold.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: gold),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: gold),
              onPressed: () async {
                final newUsername = controller.text.trim();
                if (newUsername.isNotEmpty) {
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .update({'username': newUsername});
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {
                      _userData = _loadUserData();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Username updated successfully!'),
                        backgroundColor: gold,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      appBar: AppBar(
        backgroundColor: black,
        title: Text('Settings',
            style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: gold));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading data',
                    style: TextStyle(color: Colors.red.shade300)));
          }

          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Information',
                    style: TextStyle(
                        color: gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),

                _infoTile('Username', data['username'], gold, black2),
                _infoTile('Email', data['email'], gold, black2),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _editUsername(data['username'] ?? '—'),
                    icon: const Icon(Icons.edit, color: Colors.black),
                    label: const Text('Edit Profile',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context)
                            .pushReplacementNamed('/login');
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.black),
                    label: const Text('Log Out',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(
      String label, String value, Color gold, Color backgroundColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Flexible(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
