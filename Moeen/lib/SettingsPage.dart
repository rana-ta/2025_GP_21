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

  bool hasMinLength = false;
  bool hasLower = false;
  bool hasUpper = false;
  bool hasNumber = false;
  bool hasSpecial = false;
  bool isDifferent = false;

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

  void validatePassword(String newPassword, String currentPassword) {
    setState(() {
      hasMinLength = newPassword.length >= 8;
      hasLower = RegExp(r'[a-z]').hasMatch(newPassword);
      hasUpper = RegExp(r'[A-Z]').hasMatch(newPassword);
      hasNumber = RegExp(r'[0-9]').hasMatch(newPassword);
      hasSpecial =
          RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\\/[\];]').hasMatch(newPassword);
      isDifferent = newPassword.isNotEmpty && newPassword != currentPassword;
    });
  }

  Widget buildCondition(bool condition, String text) {
    return Row(
      children: [
        Icon(
          condition ? Icons.check : Icons.close,
          color: condition ? Colors.white : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: condition ? Colors.white : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _changePassword(String email) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool isSaving = false;
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    setState(() {
      hasMinLength = false;
      hasLower = false;
      hasUpper = false;
      hasNumber = false;
      hasSpecial = false;
      isDifferent = false;
    });

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            void localValidate(String value) {
              validatePassword(value, currentPasswordController.text.trim());
              setLocalState(() {});
            }

            final allValid = hasMinLength &&
                hasLower &&
                hasUpper &&
                hasNumber &&
                hasSpecial &&
                isDifferent &&
                newPasswordController.text.isNotEmpty &&
                newPasswordController.text ==
                    confirmPasswordController.text;

            return AlertDialog(
              backgroundColor: black2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Text(
                'Change Password',
                style: TextStyle(color: gold, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: !showCurrent,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showCurrent
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setLocalState(() {
                              showCurrent = !showCurrent;
                            });
                          },
                        ),
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

                    const SizedBox(height: 12),

                    TextField(
                      controller: newPasswordController,
                      obscureText: !showNew,
                      onChanged: localValidate,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'New password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showNew
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setLocalState(() {
                              showNew = !showNew;
                            });
                          },
                        ),
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

                    const SizedBox(height: 12),

                    TextField(
                      controller: confirmPasswordController,
                      obscureText: !showConfirm,
                      onChanged: (_) => setLocalState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setLocalState(() {
                              showConfirm = !showConfirm;
                            });
                          },
                        ),
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

                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildCondition(hasMinLength, 'Must be at least 8 characters.'),
                        const SizedBox(height: 4),
                        buildCondition(hasLower, 'Must include a lowercase letter.'),
                        const SizedBox(height: 4),
                        buildCondition(hasUpper, 'Must include an uppercase letter.'),
                        const SizedBox(height: 4),
                        buildCondition(hasSpecial, 'Must contain at least one special character.'),
                        const SizedBox(height: 4),
                        buildCondition(hasNumber, 'Must contain digits (0-9).'),
                        const SizedBox(height: 4),
                        buildCondition(isDifferent, 'Cannot reuse your previous password.'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: allValid ? gold : gold.withOpacity(0.4)),
                  onPressed: !allValid || isSaving
                      ? null
                      : () async {
                    final currentPassword =
                    currentPasswordController.text.trim();
                    final newPassword =
                    newPasswordController.text.trim();

                    setLocalState(() {
                      isSaving = true;
                    });

                    try {
                      final user = FirebaseAuth.instance.currentUser!;
                      final cred = EmailAuthProvider.credential(
                        email: email,
                        password: currentPassword,
                      );

                      await user.reauthenticateWithCredential(cred);
                      await user.updatePassword(newPassword);

                      if (!mounted) return;

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                          const Text('Password updated successfully!'),
                          backgroundColor: gold,
                        ),
                      );
                    } catch (e) {
                      setLocalState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red.shade400,
                        ),
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ))
                      : const Text('Update',
                      style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
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
        title: Text(
          'Settings',
          style: TextStyle(color: gold, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: gold));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading data',
                style: TextStyle(color: Colors.red.shade300),
              ),
            );
          }

          final data = snapshot.data!;
          final username = data['username'] ?? '—';
          final email = data['email'] ?? '—';

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Information',
                  style: TextStyle(
                    color: gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),

                _infoTile('Username', username, gold, black2),
                _infoTile('Email', email, gold, black2),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _changePassword(email),
                    icon: const Icon(Icons.lock, color: Colors.black),
                    label: const Text(
                      'Change Password',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: black2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            title: Text(
                              'Log Out',
                              style: TextStyle(
                                  color: gold, fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                              'Are you sure you want to log out of your account?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.white70)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFD4AF37)),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Log Out',
                                    style: TextStyle(color: Colors.black)),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmLogout == true) {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushReplacementNamed('/login');
                        }
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.black),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
}

Widget _infoTile(
    String label,
    String value,
    Color gold,
    Color backgroundColor,
    ) {
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
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
