import 'package:flutter/material.dart';
import 'personal_criteria_page.dart'; // Nouvel import

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar et Titre
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
            // Paramètres
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildListItem(Icons.person_outline, "Manage my account"),
                  _buildListItem(Icons.lock_outline, "Privacy and safety"),
                  _buildListItem(
                    Icons.directions_walk,
                    "Personal criteria",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PersonalCriteriaPage(),
                      ),
                    ),
                  ),
                  _buildListItem(Icons.account_balance_wallet_outlined, "Balance"),
                  _buildListItem(Icons.link, "Links"),
                  _buildListItem(Icons.qr_code, "Codes"),
                  const SizedBox(height: 30),
                  const Text("Advises", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildListItem(Icons.airplane_ticket_outlined, "My Tickets"),
                  _buildListItem(Icons.support_agent, "Support"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap ?? () {}, // Utilise le callback fourni ou une fonction vide
    );
  }
}