import 'package:flutter/material.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/services/local_storage_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<List<User>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = LocalStorageService.getUsers();
    });
  }

  Future<List<User>> _filterUsers(String query, List<User> users) async {
    if (query.isEmpty) return users;
    return users.where((user) =>
    user.fullName.toLowerCase().contains(query.toLowerCase()) ||
        user.email.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Administrateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _refreshUsers();
                  },
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<User>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return const Center(child: Text('Aucun utilisateur enregistré'));
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshUsers(),
                  child: FutureBuilder<List<User>>(
                    future: _filterUsers(_searchController.text, users),
                    builder: (context, filteredSnapshot) {
                      final filteredUsers = filteredSnapshot.data ?? users;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nom: ${user.fullName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await LocalStorageService.deleteUser(user.email);
                    _refreshUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Utilisateur supprimé')),
                  );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Email: ${user.email}'),
            if (user.bankAccount != null) ...[
              const SizedBox(height: 12),
              const Text('Coordonnées bancaires:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Titulaire: ${user.bankAccount!.cardHolderName}'),
              Text('Numéro: •••• •••• •••• ${user.bankAccount!.cardNumber.substring(user.bankAccount!.cardNumber.length - 4)}'),
              Text('Expire: ${user.bankAccount!.expiryDate}'),
            ],
            const SizedBox(height: 8),
            Text(
              'Inscrit le: ${DateTime.now().toString().substring(0, 10)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}