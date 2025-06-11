import 'package:flutter/material.dart';
import 'package:soifapp/auth_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupérer la couleur de l'icône depuis le thème de l'AppBar
    // ou utiliser une couleur par défaut si non définie.
    final iconColor =
        Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.pink[700];

    return IconButton(
      icon: Icon(Icons.logout, color: iconColor),
      tooltip: 'Se déconnecter',
      onPressed: () async {
        await Supabase.instance.client.auth.signOut();
        // S'assurer que le widget est toujours monté avant de naviguer
        if (Navigator.of(context).mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthPage()),
            (Route<dynamic> route) => false,
          );
        }
      },
    );
  }
}
