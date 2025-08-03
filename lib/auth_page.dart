import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soifapp/users_page/booking_page.dart'; // Importer la nouvelle page de réservation
import 'package:soifapp/users_sign_up_page.dart'; // Importer la page d'inscription utilisateur
import 'package:soifapp/coiffeurs_page/coiffeur_home_page.dart'; // Importer la page d'accueil coiffeur
import 'package:soifapp/admins_pages/admin_home_page.dart'; // Importer la page d'accueil admin

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Écoute les changements d'état d'authentification de Firebase
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // L'utilisateur est connecté, récupérons son rôle depuis Firestore
        try {
          final docSnapshot =
              await _firestore.collection('users').doc(user.uid).get();

          if (!mounted) return;

          if (docSnapshot.exists) {
            final data = docSnapshot.data();
            final role =
                data?['role'] ?? 'client'; // 'client' est le rôle par défaut

            // Redirection en fonction du rôle
            if (role == 'client') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const BookingPage()),
              );
            } else if (role == 'coiffeur') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => const CoiffeurHomePage()),
              );
            } else if (role == 'admin') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AdminHomePage()),
              );
            }
          } else {
            // Le document utilisateur n'existe pas encore.
            debugPrint("Document utilisateur non trouvé pour l'UID: ${user.uid}");
          }
        } catch (e) {
          debugPrint("Erreur lors de la récupération du rôle: $e");
        }
      }
    });
  }

  Future<void> _performLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        // La connexion avec Firebase Auth
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // La navigation est gérée par le listener authStateChanges, donc pas besoin de code ici.
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String errorMessage = 'Une erreur de connexion est survenue.';
          if (e.code == 'user-not-found' ||
              e.code == 'wrong-password' ||
              e.code == 'invalid-credential') {
            errorMessage = 'Email ou mot de passe incorrect.';
          } else if (e.code == 'invalid-email') {
            errorMessage = 'Le format de l\'email est invalide.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Une erreur inattendue est survenue: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Obtenir le thème pour un style cohérent

    return Scaffold(
      // Pas d'AppBar pour un look plus immersif. Le contenu est protégé par SafeArea.
      body: Container(
        // Arrière-plan en dégradé pour une touche de modernité
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(
                      Icons.content_cut,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bienvenue',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connectez-vous pour continuer',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined,
                            color: theme.colorScheme.primary),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.5),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: Icon(Icons.lock_outline,
                            color: theme.colorScheme.primary),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.5),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0)),
                                textStyle: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            onPressed: _performLogin,
                            child: const Text('Se connecter'),
                          ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Pas encore de compte ?",
                            style: theme.textTheme.bodyMedium),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const UsersSignUpPage()),
                            );
                          },
                          child: Text(
                            "S'inscrire",
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
