import 'package:flutter/material.dart';
import 'bank_account_screen.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  BankAccount? _bankAccount;
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      // Validation des mots de passe
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
        );
        return;
      }

      if (_bankAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez lier un compte bancaire')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final user = User(
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          bankAccount: _bankAccount,
        );

        // Debug avant sauvegarde
        debugPrint('Tentative de sauvegarde: ${user.email}');
        debugPrint('BankAccount: ${user.bankAccount?.toJson()}');

        // Sauvegarde avec vérification
        await LocalStorageService.forceSaveUser(user);

        // Vérification après sauvegarde
        final savedUsers = await LocalStorageService.getUsers();
        debugPrint('Utilisateurs après sauvegarde: ${savedUsers.length}');
        debugPrint('Dernier utilisateur: ${savedUsers.lastOrNull?.email}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription réussie ! Vous allez être redirigé'),
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(seconds: 1));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                preFilledEmail: _emailController.text,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('ERREUR DURANT L\'INSCRIPTION: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Échec de l\'inscription: ${e.toString()}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular  (10),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Ce champ est obligatoire';
                  if (!value!.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe (min. 6 caractères)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Ce champ est obligatoire';
                  if (value!.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if  (_bankAccount != null)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Compte bancaire lié'),
                  subtitle: Text(
                    _bankAccount!.cardNumber.length >= 4
                        ? '•••• •••• •••• ${_bankAccount!.cardNumber.substring(_bankAccount!.cardNumber.length - 4)}'
                        : '•••• •••• •••• (incomplet)',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.push<BankAccount>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const  BankAccountScreen(),
                        ),
                      );
                      if (result != null) {
                        setState(() => _bankAccount = result);
                      }
                    },
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () async {
                    final result = await Navigator.push<BankAccount>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BankAccountScreen(),
                      ),
                    );
                    if (result != null) {
                      setState(() => _bankAccount = result);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize:  const Size(double.infinity, 50),
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance,  color: Colors.blue),
                      SizedBox(width: 10),
                      Text(
                        'Lier  un compte  bancaire',
                        style: TextStyle(
                          color:  Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              const  SizedBox(height: 30),
              CustomButton(
                text:  _isLoading ? 'Inscription  en cours...'  :  "S'inscrire",
                onPressed:  _isLoading  ?  null  :  _register,
              ),
              const  SizedBox(height: 20),
              TextButton(
                onPressed:  ()  =>  Navigator.pop(context),
                child:  const  Text(
                  'Vous  avez  déjà  un  compte?  Connectez-vous',
                  style:  TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void  dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}