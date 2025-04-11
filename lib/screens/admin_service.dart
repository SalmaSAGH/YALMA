import '../models/user_model.dart';

class AdminService {
  static const String adminEmail = 'admin@transport.com';
  static const String adminPassword = 'Admin123!';

  static bool isAdmin(User user) {
    return user.email == adminEmail && user.password == adminPassword;
  }
}