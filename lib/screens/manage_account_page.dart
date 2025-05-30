import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class ManageAccountPage extends StatefulWidget {
  const ManageAccountPage({super.key});

  @override
  State<ManageAccountPage> createState() => _ManageAccountPageState();
}

class _ManageAccountPageState extends State<ManageAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await LocalStorageService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUser = user;
        _emailController.text = user.email;
        _phoneController.text = user.phone;
      });
    }
  }

  bool _isStrongPassword(String password) {
    final hasMinLength = password.length >= 12;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#\$&*~%^+=?/.,;:{}()\[\]<>_\-]'));
    return hasMinLength && hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final oldPwdInput = _oldPasswordController.text.trim();
    final storedPwd = _currentUser?.password.trim();

    if (oldPwdInput != storedPwd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect old password')),
      );
      return;
    }

    if (_newPasswordController.text.isNotEmpty) {
      if (!_isStrongPassword(_newPasswordController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password must be at least 12 characters long and include uppercase, lowercase, numbers, and special characters.',
            ),
          ),
        );
        return;
      }

      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New passwords do not match')),
        );
        return;
      }
    }

    final updatedUser = User(
      fullName: _currentUser!.fullName,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _newPasswordController.text.isNotEmpty
          ? _newPasswordController.text.trim()
          : _currentUser!.password,
      bankAccount: _currentUser!.bankAccount,
    );

    try {
      await LocalStorageService.updateCurrentUser(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              suffixIcon: toggleObscure != null
                  ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: toggleObscure,
              )
                  : null,
            ),
            validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(
              helperText,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Manage My Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _emailController,
                label: 'Email',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone number',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _oldPasswordController,
                label: 'Old password',
                obscure: _obscureOld,
                toggleObscure: () => setState(() => _obscureOld = !_obscureOld),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _newPasswordController,
                label: 'New password (min. 12 characters)',
                obscure: _obscureNew,
                toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                helperText: 'Must include uppercase, lowercase, number, special character',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm new password',
                obscure: _obscureConfirm,
                toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _updateAccount,
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
