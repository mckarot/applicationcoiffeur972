import 'package:flutter/material.dart';
import 'package:soifapp/auth_page.dart';
import 'package:soifapp/users_sign_up_page.dart';
import 'package:video_player/video_player.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/background.mp4')
      ..initialize().then((_) {
        _controller.setVolume(0.0);
        _controller.setLooping(true);
        _controller.play();
        if (mounted) {
          setState(() {});
        }
      }).catchError((error) {
        debugPrint("Erreur lors de l'initialisation du lecteur vidéo: $error");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Arrière-plan vidéo commun
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: _controller.value.isInitialized
                    ? VideoPlayer(_controller)
                    : Container(color: Colors.black),
              ),
            ),
          ),
          // Dégradé commun
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // LayoutBuilder pour choisir l'interface
          LayoutBuilder(
            builder: (context, constraints) {
              // On définit un breakpoint à 700 pixels de large
              if (constraints.maxWidth > 700) {
                return const _WelcomeDesktopLayout();
              } else {
                return const _WelcomeMobileLayout();
              }
            },
          ),
        ],
      ),
    );
  }
}

// Widget pour la vue Mobile
class _WelcomeMobileLayout extends StatelessWidget {
  const _WelcomeMobileLayout();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bienvenue chez',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(
              'French Barber',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 50),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateTo(context, const UsersSignUpPage()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Rejoignez-nous'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _navigateTo(context, const AuthPage()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    child: const Text(
                      "S'identifier",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour la vue Ordinateur/Desktop
class _WelcomeDesktopLayout extends StatelessWidget {
  const _WelcomeDesktopLayout();

  @override
  Widget build(BuildContext context) {
    // Pour la version bureau, on réutilise la vue mobile
    // mais on la centre et on limite sa largeur pour la lisibilité.
    return const Center(
      child: SizedBox(
        width: 500, // Largeur maximale du contenu central
        child: _WelcomeMobileLayout(),
      ),
    );
  }
}

// Fonction utilitaire pour la navigation afin d'éviter la duplication de code
void _navigateTo(BuildContext context, Widget page) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}
