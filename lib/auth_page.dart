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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon de Coiffure - Connexion'),
        backgroundColor: Colors.pink[100], // Une couleur douce pour un salon
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.content_cut,
                    size: 80,
                    color: Colors.pink[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Connectez-vous',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'entrez_votre_email@example.com',
                      prefixIcon: Icon(Icons.email, color: Colors.pink[300]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
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
                      hintText: 'Entrez votre mot de passe',
                      prefixIcon: Icon(Icons.lock, color: Colors.pink[300]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink[400],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            textStyle: const TextStyle(
                                fontSize: 18, color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: _performLogin,
                          child: const Text('Se connecter',
                              style: TextStyle(color: Colors.white)),
                        ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const UsersSignUpPage()),
                      );
                    },
                    child: Text(
                      "Pas encore de compte ? S'inscrire",
                      style: TextStyle(color: Colors.pink[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
