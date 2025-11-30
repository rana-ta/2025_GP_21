import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  bool _trackFamily = false;
  bool _isLoading = false;

  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  bool hasMinLength = false;
  bool hasLower = false;
  bool hasUpper = false;
  bool hasNumber = false;
  bool hasSpecial = false;

  @override
  void initState() {
    super.initState();

    _usernameFocus.addListener(() async {
      if (!_usernameFocus.hasFocus) await _checkUsername();
    });

    _emailFocus.addListener(() async {
      if (!_emailFocus.hasFocus) await _checkEmail();
    });
  }

  Future<void> _checkUsername() async {
    String username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() => _usernameError = 'Please enter your username.');
    } else {
      setState(() => _usernameError = null);
    }
  }

  Future<void> _checkEmail() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
        .hasMatch(email)) {
      setState(() => _emailError =
      'Please enter a valid email address in the correct format.');
      return;
    }
    List<String> methods =
    await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    if (methods.isNotEmpty) {
      setState(() =>
      _emailError = 'This email is already in use. Please log in instead.');
    } else {
      setState(() => _emailError = null);
    }
  }

  void _validatePassword(String value) {
    setState(() {
      hasMinLength = value.length >= 8;
      hasLower = RegExp(r'[a-z]').hasMatch(value);
      hasUpper = RegExp(r'[A-Z]').hasMatch(value);
      hasNumber = RegExp(r'[0-9]').hasMatch(value);
      hasSpecial =
          RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\\/[\];]').hasMatch(value);
    });

    if (value.isEmpty) {
      setState(() => _passwordError = 'Please enter your password.');
    } else {
      setState(() => _passwordError = null);
    }
  }

  bool get _allPasswordConditionsMet =>
      hasMinLength && hasLower && hasUpper && hasNumber && hasSpecial;

  Future<void> _submitForm() async {
    await _checkUsername();
    await _checkEmail();
    _validatePassword(_passwordController.text);

    if (!_allPasswordConditionsMet) {
      setState(() => _passwordError = 'Please meet all password requirements.');
    }

    if (_usernameError != null ||
        _emailError != null ||
        _passwordError != null) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'trackFamily': _trackFamily,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _emailError = e.code == 'email-already-in-use'
            ? 'This email is already in use. Please log in instead.'
            : null;
        _passwordError = e.code == 'weak-password'
            ? 'Password is too weak. Please use a stronger password.'
            : _passwordError;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, Color gold,
      {String? errorText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      errorText: errorText,
      errorMaxLines: 5,
      errorStyle: const TextStyle(
        color: Colors.redAccent,
        fontSize: 13,
        height: 1.3,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: gold, width: 1.4),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _conditionRow(bool ok, String text) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check : Icons.close,
          color: ok ? Colors.white : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: ok ? Colors.white : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const glassBg = Color(0xAA1E1E1E);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 360,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: glassBg,
                    borderRadius: BorderRadius.circular(24),
                    border:
                    Border.all(color: Colors.white.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Create Account ✨',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: gold,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Username
                          TextFormField(
                            controller: _usernameController,
                            focusNode: _usernameFocus,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Username', gold,
                                errorText: _usernameError),
                            validator: (_) => _usernameError,
                            onChanged: (_) {
                              String username =
                              _usernameController.text.trim();
                              if (username.isEmpty) {
                                setState(() => _usernameError =
                                'Please enter your username.');
                              } else {
                                setState(() => _usernameError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Email', gold,
                                errorText: _emailError),
                            validator: (_) => _emailError,
                            onChanged: (_) => _checkEmail(),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Password', gold,
                                errorText: _passwordError),
                            validator: (_) => _passwordError,
                            onChanged: _validatePassword,
                          ),

                          const SizedBox(height: 10),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _conditionRow(
                                  hasMinLength, 'At least 8 characters.'),
                              const SizedBox(height: 4),
                              _conditionRow(hasLower,
                                  'Includes a lowercase letter.'),
                              const SizedBox(height: 4),
                              _conditionRow(hasUpper,
                                  'Includes an uppercase letter.'),
                              const SizedBox(height: 4),
                              _conditionRow(
                                  hasSpecial,
                                  'Contains at least one special character.'),
                              const SizedBox(height: 4),
                              _conditionRow(
                                  hasNumber, 'Contains numbers (0–9).'),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Checkbox(
                                value: _trackFamily,
                                onChanged: (value) => setState(
                                        () => _trackFamily = value ?? false),
                                checkColor: Colors.black,
                                activeColor: gold,
                              ),
                              const Text('Track family members',
                                  style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 22),

                          _isLoading
                              ? const CircularProgressIndicator(color: gold)
                              : ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 80, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/login'),
                            child: const Text(
                              'Already have an account? Log in',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

