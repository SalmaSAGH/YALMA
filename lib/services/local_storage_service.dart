import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport_app/models/user_model.dart';
import 'dart:convert';

import '../screens/admin_service.dart';

class LocalStorageService {
  static const String _usersKey = 'registered_users_2.0';
  static SharedPreferences? _prefs;

  // Initialisation explicite
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('Initialisation Storage - Clés existantes: ${_prefs?.getKeys()}');
    final rawData = _prefs?.getStringList(_usersKey);
    debugPrint('Contenu brut de $_usersKey: $rawData');

  }

  static Future<void> saveUser(User user) async {
    try {
      await _ensureInitialized();
      final currentUsers = await getUsers();

      // Éviter les doublons
      if (currentUsers.any((u) => u.email == user.email)) {
        throw Exception('Cet email existe déjà');
      }

      final updatedUsers = [...currentUsers, user];
      final usersJson = updatedUsers.map((u) => json.encode(u.toJson())).toList();

      // Sauvegarde atomique
      final success = await _prefs!.setStringList(_usersKey, usersJson);
      if (!success) {
        debugPrint('Échec setStringList pour $_usersKey');
      }

      if (!success) {
        throw Exception('Échec de la sauvegarde');
      }

      debugPrint('SAUVEGARDE RÉUSSIE - ${updatedUsers.length} utilisateurs');
      debugPrint('Dernier utilisateur: ${user.email}');
    } catch (e) {
      debugPrint('ERREUR CRITIQUE saveUser: $e');
      rethrow;
    }
  }

  static Future<void> createAdminUser() async {
    final prefs = await SharedPreferences.getInstance();
    final adminExists = (await getUsers()).any((u) => u.email == AdminService.adminEmail);

    if (!adminExists) {
      final admin = User(
        fullName: 'Administrateur',
        email: AdminService.adminEmail,
        password: AdminService.adminPassword,
          phone: '+10000000000',
      );

      debugPrint('Admin existe déjà ? $adminExists');
      if (!adminExists) {
        debugPrint('Création de l\'admin...');
      }

      await saveUser(admin);
    }
  }

  static Future<List<User>> getUsers() async {
    await _ensureInitialized();
    try {
      final usersJson = _prefs?.getStringList(_usersKey) ?? [];
      return usersJson.map((jsonStr) {
        final userMap = json.decode(jsonStr) as Map<String, dynamic>;
        return User.fromJson(userMap);
      }).toList();
    } catch (e) {
      debugPrint('Erreur chargement: $e');
      return [];
    }
  }

  static Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> deleteUser(String email) async {
    await _ensureInitialized();
    final users = await getUsers();
    users.removeWhere((user) => user.email == email);
    await _prefs!.setStringList(_usersKey,
        users.map((u) => json.encode(u.toJson())).toList());
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }

  static Future<void> forceSaveUser(User user) async {
    await _ensureInitialized();
    try {
      final currentUsers = await getUsers();
      final updatedUsers = [...currentUsers, user];

      // Vérification avant sauvegarde
      debugPrint('Users avant sauvegarde:');
      currentUsers.forEach((u) => debugPrint(u.email));

      // Sauvegarde forcée
      final success = await _prefs!.setStringList(
          _usersKey,
          updatedUsers.map((u) => json.encode(u.toJson())).toList()
      );

      if (!success) throw Exception('Échec écriture SharedPreferences');

      // Vérification après
      final savedData = _prefs!.getStringList(_usersKey);
      debugPrint('Données brutes sauvegardées: ${savedData?.length} éléments');
    } catch (e) {
      debugPrint('ERREUR CRITIQUE forceSaveUser: $e');
      rethrow;
    }
  }
}