import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soifapp/booking_page.dart';
import 'package:soifapp/planning_page.dart';
import 'package:soifapp/salon_location_page.dart'; // Importer la page Localisation
import 'package:soifapp/change_password_page.dart'; // Importer la nouvelle page
import 'package:soifapp/widgets/modern_bottom_nav_bar.dart'; // Importer le widget refactorisé
import 'package:soifapp/models/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _currentIndex = 3; // L'onglet Paramètres est maintenant à l'index 3

  void _onNavBarTap(int index) {
    if (index == _currentIndex && index == 3)
      return; // Déjà sur Paramètres et on clique sur Paramètres

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BookingPage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PlanningPage()),
      );
    } else if (index == 2) {
      // Nouvel onglet Localisation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SalonLocationPage()),
      );
    } else {
      // index == 3 (Paramètres)
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Gardé pour les options de thème

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        // La couleur s'adaptera grâce à AppBarTheme dans main.dart
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          SwitchListTile(
            title: const Text('Mode Sombre'),
            value: themeProvider.isDarkMode,
            onChanged: (bool value) {
              themeProvider.toggleTheme(value);
            },
            secondary: Icon(
              themeProvider.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.color_lens_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: const Text('Thème du système'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          ListTile(
            leading: Icon(Icons.light_mode_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: const Text('Thème clair'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          ListTile(
            leading: Icon(Icons.dark_mode_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: const Text('Thème sombre'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.password_rounded,
                color: Theme.of(context).colorScheme.primary),
            title: const Text('Modifier le mot de passe'),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                size: 18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ChangePasswordPage()),
              );
            },
          ),
          // Ajoutez d'autres paramètres ici
        ],
      ),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
