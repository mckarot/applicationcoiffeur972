import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        final userId = session.user.id;
        // Récupère le profil depuis Supabase
        final response = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .maybeSingle();

        if (!mounted) return;

        // Si le profil n'est pas trouvé (response est null), il peut s'agir d'un nouvel utilisateur
        // dont le profil est en cours de création. On attend le prochain événement d'authentification
        // (comme après la confirmation de l'e-mail) au lieu de planter.
        // Cela résout la "race condition" lors de l'inscription.
        if (response == null) {
          // On pourrait logger cet événement, mais pour l'instant, on arrête l'exécution ici pour éviter l'erreur.
          return;
        }

        final role = response['role'] ?? 'user';

        if (role == 'user') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const BookingPage()),
          );
        } else if (role == 'coiffeur') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CoiffeurHomePage()),
          );
        } else if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminHomePage()),
          );
        } else {
          // Par défaut, page utilisateur
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const BookingPage()),
          );
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
        final AuthResponse res = await _supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // La navigation vers BookingPage est gérée par onAuthStateChange
        // en cas de succès (res.user != null et session active).
        // Si signInWithPassword réussit mais que l'utilisateur n'est pas confirmé,
        // Supabase lèvera une AuthException qui sera attrapée ci-dessous.
        if (mounted) {
          if (res.user == null && res.session == null) {
            // Ce cas est généralement couvert par AuthException pour les e-mails non confirmés ou les mauvais identifiants.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Échec de la connexion. Vérifiez vos identifiants ou confirmez votre e-mail.')),
            );
          }
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de connexion: ${e.message}')),
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
