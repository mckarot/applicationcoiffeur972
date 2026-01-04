import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soifapp/users_page/booking_page.dart'; // Importer la nouvelle page de réservation
import 'package:soifapp/users_sign_up_page.dart'; // Importer la page d'inscription utilisateur
import 'package:soifapp/coiffeurs_page/coiffeur_home_page.dart'; // Importer la page d'accueil coiffeur
import 'package:soifapp/admins_pages/admin_home_page.dart'; // Importer la page d'accueil admin
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

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
  bool _isPasswordVisible = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        try {
          final docSnapshot =
              await _firestore.collection('users').doc(user.uid).get();
          if (!mounted) return;
          if (docSnapshot.exists) {
            final data = docSnapshot.data();
            final role = data?['role'] ?? 'client';
            _redirectUser(role);
          } else {
            debugPrint("Document utilisateur non trouvé pour l'UID: ${user.uid}");
          }
        } catch (e) {
          debugPrint("Erreur lors de la récupération du rôle: $e");
        }
      }
    });
  }

  void _redirectUser(String role) {
    if (!mounted) return;
    Widget page;
    switch (role) {
      case 'coiffeur':
        page = const CoiffeurHomePage();
        break;
      case 'admin':
        page = const AdminHomePage();
        break;
      case 'client':
      default:
        page = const BookingPage();
        break;
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => page));
  }

  Future<void> _performLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String errorMessage = 'Une erreur de connexion est survenue.';
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          errorMessage = 'Email ou mot de passe incorrect.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Le format de l\'email est invalide.';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Une erreur inattendue est survenue: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
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

  Future<void> _forgotPassword() async {
    final emailDialogController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Réinitialiser le mot de passe'),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: emailDialogController,
              decoration: const InputDecoration(
                labelText: 'Entrez votre email',
                hintText: 'vous@exemple.com',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  (value == null || value.isEmpty || !value.contains('@'))
                      ? 'Veuillez entrer un email valide'
                      : null,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Envoyer'),
              onPressed: () async {
                if (dialogFormKey.currentState!.validate()) {
                  try {
                    await _auth.sendPasswordResetEmail(
                        email: emailDialogController.text.trim());
                    if (!mounted) return;
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Un lien de réinitialisation a été envoyé.')));
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.message ?? "Une erreur est survenue.")));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Si l'écran est large, on contraint la largeur du formulaire
              if (constraints.maxWidth > 600) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: _buildAuthForm(),
                  ),
                );
              } else {
                // Sur mobile, on prend la largeur disponible
                return _buildAuthForm();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    final theme = Theme.of(context);
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surface.withOpacity(0.5),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none),
      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      prefixIconColor: theme.colorScheme.primary,
      errorStyle: TextStyle(color: theme.colorScheme.error.withOpacity(0.85)),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(Icons.content_cut,
                  size: 80, color: theme.colorScheme.primary),
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
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: _emailController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    (value == null || value.isEmpty || !value.contains('@'))
                        ? 'Veuillez entrer un email valide'
                        : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: theme.colorScheme.primary.withOpacity(0.7)),
                    onPressed: () =>
                        setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                obscureText: !_isPasswordVisible,
                validator: (value) =>
                    (value == null || value.isEmpty || value.length < 6)
                        ? 'Le mot de passe doit faire au moins 6 caractères'
                        : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: Text('Mot de passe oublié ?',
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const UsersSignUpPage())),
                    child: Text("S'inscrire",
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLegalText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Impossible d\'ouvrir le lien : $urlString')));
      }
    }
  }

  Widget _buildLegalText(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = TextStyle(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontSize: 12,
        ),
        children: [
          const TextSpan(text: 'En continuant, vous acceptez notre '),
          TextSpan(
            text: 'Politique de confidentialité',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchURL(
                  'https://coiffure-salon.web.app/politique-de-confidentialite.html'),
          ),
          const TextSpan(text: ' et nos '),
          TextSpan(
            text: 'Conditions d\'utilisation',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchURL(
                  'https://coiffure-salon.web.app/conditions-d-utilisation.html'),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
