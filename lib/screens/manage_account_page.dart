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
    } else {
      debugPrint("Aucun utilisateur actuellement connecté !");
    }
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final oldPwdInput = _oldPasswordController.text.trim();
    final storedPwd = _currentUser?.password.trim();

    debugPrint("Mot de passe saisi : '$oldPwdInput'");
    debugPrint("Mot de passe enregistré : '$storedPwd'");

    if (oldPwdInput != storedPwd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ancien mot de passe incorrect')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les nouveaux mots de passe ne correspondent pas')),
      );
      return;
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
        const SnackBar(content: Text('Compte mis à jour avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Gérer mon compte")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez entrer un email'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez entrer un numéro'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Ancien mot de passe'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Obligatoire pour modifier'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nouveau mot de passe (optionnel)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmer nouveau mot de passe'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _updateAccount,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
