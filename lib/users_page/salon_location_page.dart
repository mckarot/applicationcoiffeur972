import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:soifapp/users_page/booking_page.dart';
import 'package:soifapp/users_page/planning_page.dart';
import 'package:soifapp/users_page/settings_page.dart';
import 'package:soifapp/widgets/logout_button.dart';
import 'package:soifapp/widgets/modern_bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart'; // Importez le package url_launcher

class SalonLocationPage extends StatefulWidget {
  const SalonLocationPage({super.key});

  @override
  State<SalonLocationPage> createState() => _SalonLocationPageState();
}

class _SalonLocationPageState extends State<SalonLocationPage> {
  int _currentIndex = 2; // L'onglet Localisation sera à l'index 2
  // Définir les informations de contact
  final String _phoneNumber =
      '+33123456789'; // Format international pour plus de compatibilité
  final String _email = 'contact@coifapp.com';

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

  // Fonction pour lancer l'application de cartographie
  Future<void> _launchMap() async {
    const String address = '123 Rue de la Coiffure, 75000 Paris, France';
    // Encode l'adresse pour l'URL
    final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    final Uri appleMapsUrl =
        Uri.parse('http://maps.apple.com/?q=${Uri.encodeComponent(address)}');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl);
    } else {
      // Fallback si aucune application de carte n'est disponible
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Impossible d\'ouvrir l\'application de cartographie.'),
          ),
        );
      }
    }
  }

  // Fonction pour lancer l'application téléphone
  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: _phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de lancer l\'application téléphone.'),
          ),
        );
      }
    }
  }

  // Fonction pour lancer l'application email
  Future<void> _launchEmail() async {
    // Pour des emails plus complexes avec sujet et corps :
    // final Uri emailUri = Uri(scheme: 'mailto', path: _email, query: 'subject=Prise de contact&body=Bonjour,');
    final Uri emailUri = Uri(scheme: 'mailto', path: _email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de lancer l\'application de messagerie.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notre Emplacement'),
        actions: [
          const LogoutButton(), // Ajout du bouton de déconnexion
        ],
      ),
      body: Center(
        // Enveloppe le contenu dans un SingleChildScrollView pour permettre le défilement
        // Le Padding est déplacé à l'intérieur pour s'appliquer au contenu scrollable
        child: SingleChildScrollView(
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
              ElevatedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text('Voir sur la carte'),
                onPressed: () {
                  // Appelle la fonction pour lancer la carte
                  _launchMap();
                },
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
              const SizedBox(height: 15),
              _buildContactRow(
                icon: Icons.phone_outlined,
                text: '01 23 45 67 89', // Texte affiché pour l'utilisateur
                onTap: _launchPhone,
              ),
              const SizedBox(height: 8),
              _buildContactRow(
                icon: Icons.email_outlined,
                text: _email,
                onTap: _launchEmail,
              ),
              const SizedBox(height: 30),
              Text(
                'Nos réseaux sociaux',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              // Pour rendre les icônes scrollables horizontalement tout en les gardant
              // centrées, nous utilisons un LayoutBuilder pour obtenir la largeur de l'écran
              // et forcer la Row à avoir au moins cette largeur.
              SizedBox(
                height: 60, // Hauteur pour les boutons et un peu d'espace
                child: LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    // Le clipBehavior.none est important pour que l'ombre du InkWell ne soit pas coupée.
                    clipBehavior: Clip.none,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _buildSocialButton(
                            icon: FontAwesomeIcons.facebookF,
                            color: const Color(0xFF3b5998), // Facebook
                            tooltip: 'Facebook',
                            onPressed: () {
                              // TODO: Implémenter le lien vers Facebook
                            },
                          ),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.instagram,
                            color: const Color(0xFFE1306C), // Instagram
                            tooltip: 'Instagram',
                            onPressed: () {
                              // TODO: Implémenter le lien vers Instagram
                            },
                          ),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.xTwitter,
                            color: const Color(0xFF000000), // X/Twitter
                            tooltip: 'X (Twitter)',
                            onPressed: () {
                              // TODO: Implémenter le lien vers X
                            },
                          ),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.tiktok,
                            color: const Color(0xFF000000), // TikTok
                            tooltip: 'TikTok',
                            onPressed: () {
                              // TODO: Implémenter le lien vers TikTok
                            },
                          ),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.whatsapp,
                            color: const Color(0xFF25D366), // WhatsApp
                            tooltip: 'WhatsApp',
                            onPressed: () {
                              // TODO: Implémenter le lien vers WhatsApp
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          ModernBottomNavBar(currentIndex: _currentIndex, onTap: _onNavBarTap),
    );
  }

  // Widget pour créer un bouton de réseau social rond
  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25), // Pour l'effet d'ondulation
          child: CircleAvatar(
            radius: 25,
            backgroundColor: color,
            child: FaIcon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  // Widget pour créer une ligne de contact cliquable (téléphone, email)
  Widget _buildContactRow({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.underline,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
