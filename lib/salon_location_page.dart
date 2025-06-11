import 'package:flutter/material.dart';
import 'package:soifapp/booking_page.dart';
import 'package:soifapp/planning_page.dart';
import 'package:soifapp/settings_page.dart';
import 'package:soifapp/widgets/modern_bottom_nav_bar.dart';

class SalonLocationPage extends StatefulWidget {
  const SalonLocationPage({super.key});

  @override
  State<SalonLocationPage> createState() => _SalonLocationPageState();
}

class _SalonLocationPageState extends State<SalonLocationPage> {
  int _currentIndex = 2; // L'onglet Localisation sera à l'index 2

  void _onNavBarTap(int index) {
    if (index == _currentIndex && index == 2) return; // Déjà sur Localisation

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
    } else if (index == 3) {
      // Nouvel index pour Paramètres
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    } else {
      // index == 2 (Localisation)
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notre Emplacement'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.store_mall_directory_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Salon CoifApp',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                '123 Rue de la Coiffure\n75000 Paris, France',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Text(
                'Horaires d\'ouverture :\nLundi - Samedi : 9h00 - 19h00\nDimanche : Fermé',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Text(
                'Nous contacter :',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Téléphone : 01 23 45 67 89\nEmail : contact@coifapp.com',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text('Voir sur la carte (Fictif)'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ouverture de la carte (simulation)...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
