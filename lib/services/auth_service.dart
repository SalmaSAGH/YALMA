import 'package:transport_app/services/local_storage_service.dart';
import 'package:transport_app/models/user_model.dart';

class AuthService {
  static Future<bool> registerUser(User user) async {
    try {
      await LocalStorageService.saveUser(user);
      return true;
    } catch (e) {
      throw Exception('Erreur d\'inscription: $e');
    }
  }
}