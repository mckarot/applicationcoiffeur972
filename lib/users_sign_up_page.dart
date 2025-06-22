import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersSignUpPage extends StatefulWidget {
  const UsersSignUpPage({super.key});

  @override
  State<UsersSignUpPage> createState() => _UsersSignUpPageState();
}

class _UsersSignUpPageState extends State<UsersSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Le rôle est fixe pour cette page d'inscription utilisateur
  final String _selectedRole = 'user';

  Future<void> _performSignUp() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Les mots de passe ne correspondent pas.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final AuthResponse res = await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (res.user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Erreur d\'inscription: utilisateur non retourné après la création.')),
            );
          }
          return;
        }

        try {
          if (mounted) {
            await _supabase.from('profiles').insert({
              'id': res.user!.id,
              'nom': _nameController.text.trim(),
              'telephone': _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              'role': _selectedRole, // Utilise le rôle fixe 'user'
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Inscription réussie ! Veuillez vérifier vos e-mails pour confirmer votre compte.')),
            );

            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
        } catch (profileError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Erreur lors de la création du profil: $profileError. L\'utilisateur a été créé mais le profil n\'a pas pu être sauvegardé.')),
            );
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
        }
      } on AuthException catch (authError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur d\'inscription: ${authError.message}')),
          );
          print('Erreur d\'inscription: ${authError.message}');
        }
      } catch (unexpectedError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Une erreur système inattendue est survenue: $unexpectedError')),
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
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Colors.pink[100],
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
                  Icon(Icons.person_add_alt_1,
                      size: 80, color: Colors.pink[300]),
                  const SizedBox(height: 20),
                  Text(
                    'Rejoignez-nous !',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[700]),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(Icons.person, color: Colors.pink[300]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0))),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Veuillez entrer votre nom'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Colors.pink[300]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0))),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value == null || value.isEmpty || !value.contains('@')
                            ? 'Veuillez entrer un email valide'
                            : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                        labelText: 'Téléphone (optionnel)',
                        prefixIcon: Icon(Icons.phone, color: Colors.pink[300]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0))),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: Icon(Icons.lock, color: Colors.pink[300]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0))),
                    obscureText: true,
                    validator: (value) => value == null || value.length < 6
                        ? 'Le mot de passe doit contenir au moins 6 caractères'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        prefixIcon:
                            Icon(Icons.lock_outline, color: Colors.pink[300]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0))),
                    obscureText: true,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Veuillez confirmer le mot de passe'
                        : null,
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
                                  borderRadius: BorderRadius.circular(12.0))),
                          onPressed: _performSignUp,
                          child: const Text("S'inscrire",
                              style: TextStyle(color: Colors.white)),
                        ),
                  TextButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context); // Retour à la page de connexion
                      }
                    },
                    child: Text('Déjà un compte ? Se connecter',
                        style: TextStyle(color: Colors.pink[700])),
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
