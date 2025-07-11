import 'package:flutter/material.dart';
import 'package:soifapp/auth_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Se déconnecter'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      // S'assurer que le widget est toujours monté avant de naviguer
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer la couleur de l'icône depuis le thème de l'AppBar
    // ou utiliser une couleur par défaut si non définie.
    final iconColor =
        Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.pink[700];

    return IconButton(
      icon: Icon(Icons.logout, color: iconColor),
      tooltip: 'Se déconnecter',
      onPressed: () => _showLogoutConfirmationDialog(context),
    );
  }
}
