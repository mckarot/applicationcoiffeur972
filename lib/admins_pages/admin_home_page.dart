import 'package:flutter/material.dart';
import 'package:soifapp/admins_pages/manage_coiffeurs_page.dart'; // Importer la nouvelle page
import 'package:soifapp/widgets/logout_button.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Administrateur'),
        actions: const [LogoutButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.manage_accounts),
            label: const Text('Gérer les Coiffeurs'),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManageCoiffeursPage()));
            },
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
          ),
        ),
      ),
    );
  }
}
