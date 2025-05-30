import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport_app/models/user_model.dart';
import 'dart:convert';
import '../screens/admin_service.dart';

class LocalStorageService {
  static const String _usersKey = 'registered_users_2.0';
  static const String _currentUserKey = 'current_user_email';
  static SharedPreferences? _prefs;

  // Initialisation
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('Initialisation Storage - Clés existantes: ${_prefs?.getKeys()}');
  }

  static Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Enregistrement forcé
  static Future<void> forceSaveUser(User user) async {
    await _ensureInitialized();
    try {
      final currentUsers = await getUsers();
      final updatedUsers = [...currentUsers, user];

      final success = await _prefs!.setStringList(
        _usersKey,
        updatedUsers.map((u) => json.encode(u.toJson())).toList(),
      );

      if (!success) throw Exception('Échec de la sauvegarde forcée');
      debugPrint('Utilisateur forcément sauvegardé: ${user.email}');
    } catch (e) {
      debugPrint('ERREUR forceSaveUser: $e');
      rethrow;
    }
  }

  // Enregistrement normal
  static Future<void> saveUser(User user) async {
    await _ensureInitialized();
    try {
      final currentUsers = await getUsers();
      if (currentUsers.any((u) => u.email == user.email)) {
        throw Exception('Cet email existe déjà');
      }

      final updatedUsers = [...currentUsers, user];
      final usersJson = updatedUsers.map((u) => json.encode(u.toJson())).toList();

      final success = await _prefs!.setStringList(_usersKey, usersJson);
      if (!success) throw Exception('Échec de la sauvegarde');

      debugPrint('Utilisateur sauvegardé: ${user.email}');
    } catch (e) {
      debugPrint('ERREUR saveUser: $e');
      rethrow;
    }
  }

  // Mettre à jour un utilisateur spécifique
  static Future<void> updateUser(User oldUser, User newUser) async {
    await _ensureInitialized();
    try {
      final users = await getUsers();
      final index = users.indexWhere((u) => u.email == oldUser.email);

      if (index == -1) throw Exception('Utilisateur non trouvé');

      users[index] = newUser;
      final success = await _prefs!.setStringList(
        _usersKey,
        users.map((u) => json.encode(u.toJson())).toList(),
      );

      if (!success) throw Exception('Échec de la mise à jour');

      if (oldUser.email == newUser.email) {
        await setCurrentUser(newUser);
      }
    } catch (e) {
      debugPrint('ERREUR updateUser: $e');
      rethrow;
    }
  }

  // 🔁 Mettre à jour les infos du compte connecté
  static Future<void> updateCurrentUser(User updatedUser) async {
    await _ensureInitialized();
    final currentEmail = _prefs?.getString(_currentUserKey);

    if (currentEmail == null) {
      throw Exception("Aucun utilisateur connecté.");
    }

    final users = await getUsers();
    final index = users.indexWhere((u) => u.email == currentEmail);

    if (index == -1) {
      throw Exception("Utilisateur courant non trouvé.");
    }

    // Vérifie que le nouvel email n'appartient pas à un autre utilisateur
    if (updatedUser.email != currentEmail &&
        users.any((u) => u.email == updatedUser.email)) {
      throw Exception("Cet email est déjà utilisé par un autre utilisateur.");
    }

    users[index] = updatedUser;

    final success = await _prefs!.setStringList(
      _usersKey,
      users.map((u) => json.encode(u.toJson())).toList(),
    );

    if (!success) {
      throw Exception("Erreur lors de la mise à jour de l'utilisateur.");
    }

    // Met à jour l'email courant si changé
    await _prefs?.setString(_currentUserKey, updatedUser.email);
    debugPrint("Utilisateur mis à jour: ${updatedUser.email}");
  }

  // Gestion de l'utilisateur courant
  static Future<void> setCurrentUser(User user) async {
    await _ensureInitialized();
    await _prefs?.setString(_currentUserKey, user.email);
  }

  static Future<User?> getCurrentUser() async {
    await _ensureInitialized();
    final email = _prefs?.getString(_currentUserKey);
    if (email == null) return null;

    final users = await getUsers();
    try {
      return users.firstWhere((user) => user.email == email);
    } catch (e) {
      debugPrint('Utilisateur courant non trouvé: $email');
      return null;
    }
  }

  static Future<void> clearCurrentUser() async {
    await _ensureInitialized();
    await _prefs?.remove(_currentUserKey);
  }

  static Future<List<User>> getUsers() async {
    await _ensureInitialized();
    try {
      final usersJson = _prefs?.getStringList(_usersKey) ?? [];
      return usersJson.map((jsonStr) => User.fromJson(json.decode(jsonStr))).toList();
    } catch (e) {
      debugPrint('Erreur chargement utilisateurs: $e');
      return [];
    }
  }

  static Future<void> deleteUser(String email) async {
    await _ensureInitialized();
    final users = await getUsers();
    users.removeWhere((user) => user.email == email);
    await _prefs!.setStringList(
      _usersKey,
      users.map((u) => json.encode(u.toJson())).toList(),
    );
  }

  static Future<void> createAdminUser() async {
    final adminExists = (await getUsers()).any((u) => u.email == AdminService.adminEmail);
    if (!adminExists) {
      await saveUser(User(
        fullName: 'Administrateur',
        email: AdminService.adminEmail,
        password: AdminService.adminPassword,
        phone: '+10000000000',
      ));
    }
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
