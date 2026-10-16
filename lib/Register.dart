import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:krushi/Homepage.dart';
import 'package:krushi/Login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _shopController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;

  static const Color _green = Color(0xFF287A3D);
  static const Color _darkGreen = Color(0xFF174D2A);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _shopController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Account could not be created.');
    }

    await FirebaseFirestore.instance.collection('user').doc(user.uid).set({
      'uid': user.uid,
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'shop': _shopController.text.trim(),
      'location': _locationController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Homepage()),
    );
  } on FirebaseAuthException catch (e) {
    if (mounted) _showMessage(_authErrorMessage(e));
  } catch (e) {
    if (mounted) _showMessage('Registration failed: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'Please check your internet connection and try again.';
      default:
        return error.message ?? 'Registration failed. Please try again.';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _green),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7FAF6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1E9DF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1E9DF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _green, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6EF),
      body: Stack(
        children: [
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_darkGreen, _green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(38),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 54,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Krushi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Grow your business with us',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Card(
                        elevation: 8,
                        shadowColor: _darkGreen.withValues(alpha: 0.14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Create your account',
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF203326),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Enter your details to get started.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _inputDecoration(
                                    label: 'Full name',
                                    icon: Icons.person_outline,
                                  ),
                                  validator: (value) =>
                                      _required(value, 'Name'),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: _inputDecoration(
                                    label: 'Email address',
                                    icon: Icons.email_outlined,
                                  ),
                                  validator: (value) {
                                    final required =
                                        _required(value, 'Email');
                                    if (required != null) return required;
                                    if (!RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+$',
                                    ).hasMatch(value!.trim())) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDecoration(
                                    label: 'Mobile number',
                                    icon: Icons.phone_outlined,
                                  ),
                                  validator: (value) {
                                    final required =
                                        _required(value, 'Mobile number');
                                    if (required != null) return required;
                                    if (value!.trim().length < 10) {
                                      return 'Enter a valid mobile number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _shopController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _inputDecoration(
                                    label: 'Shop or business name',
                                    icon: Icons.storefront_outlined,
                                  ),
                                  validator: (value) =>
                                      _required(value, 'Shop name'),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _locationController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _inputDecoration(
                                    label: 'Location',
                                    icon: Icons.location_on_outlined,
                                  ),
                                  validator: (value) =>
                                      _required(value, 'Location'),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _hidePassword,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  decoration: _inputDecoration(
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _hidePassword = !_hidePassword,
                                      ),
                                      icon: Icon(
                                        _hidePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 6) {
                                      return 'Use at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _green,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          _green.withValues(alpha: 0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Create account',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => Login(),
                                            ),
                                          );
                                        },
                                  child: const Text(
                                    'Already have an account? Sign in',
                                    style: TextStyle(
                                      color: _green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Growing together, one harvest at a time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF55705A),
                          fontSize: 13,
                        ),
                      ),
                    ],
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