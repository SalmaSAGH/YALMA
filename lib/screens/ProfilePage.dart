import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'MyTicketsPage.dart';
import 'manage_account_page.dart';
import 'personal_criteria_page.dart';
import '../services/local_storage_service.dart';
import 'login_screen.dart';
import '../providers/ThemeProvider.dart'; // 👈 Pour accéder à ThemeProvider

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Column(
              children: const [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  'Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildListItem(
                    Icons.person_outline,
                    "Manage my account",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageAccountPage()),
                    ),
                  ),
                  _buildListItem(Icons.lock_outline, "Privacy and safety"),
                  _buildListItem(
                    Icons.directions_walk,
                    "Personal criteria",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PersonalCriteriaPage()),
                    ),
                  ),

                  // 🌗 Mode Sombre / Clair
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) => SwitchListTile(
                      secondary: const Icon(Icons.dark_mode),
                      title: const Text('Dark Mode'),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) => themeProvider.toggleTheme(value),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text("Advises", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildListItem(
                    Icons.airplane_ticket_outlined,
                    "My Tickets",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyTicketsPage()),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  _buildListItem(
                    Icons.logout,
                    "Log out",
                    onTap: () async {
                      await LocalStorageService.clearCurrentUser();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildListItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap ?? () {},
    );
  }
}
