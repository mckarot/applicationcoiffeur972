import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
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
  String _countryDialCode = ''; // Pour stocker le code du pays
  final SupabaseClient _supabase = Supabase.instance.client;

  // Le rôle est fixe pour cette page d'inscription utilisateur
  final String _selectedRole = 'user';

  Future<void> _performSignUp() async {
    // On vérifie si le formulaire est valide
    if (!_formKey.currentState!.validate()) {
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

      // Insertion du profil après la création de l'utilisateur
      try {
        final String fullPhoneNumber =
            '$_countryDialCode${_phoneController.text.trim()}';
        if (mounted) {
          await _supabase.from('profiles').insert({
            'id': res.user!.id,
            'nom': _nameController.text.trim(),
            'telephone': fullPhoneNumber.isEmpty ? null : fullPhoneNumber,
            'role': _selectedRole,
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Méthode pour construire les champs de saisie de manière cohérente
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.pink[300]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.pink[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(color: Colors.grey[800]),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
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
                  _buildInputField(
                    controller: _nameController,
                    label: 'Nom complet',
                    icon: Icons.person,
                    hint: 'Entrez votre nom',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Veuillez entrer votre nom'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    hint: 'entrez_votre_email@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value == null || value.isEmpty || !value.contains('@')
                            ? 'Veuillez entrer un email valide'
                            : null,
                  ),
                  const SizedBox(height: 20),
                  IntlPhoneField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.pink[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                            width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    initialCountryCode:
                        'MQ', // Pays initial défini sur Martinique
                    disableLengthCheck:
                        true, // Désactive la validation de longueur par défaut du package
                    showDropdownIcon: true,
                    dropdownIcon:
                        Icon(Icons.arrow_drop_down, color: Colors.pink[300]),
                    dropdownTextStyle: TextStyle(color: Colors.grey[800]),
                    style: TextStyle(color: Colors.grey[800]),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (phone) {
                      if (phone == null || phone.number.trim().isEmpty) {
                        return 'Veuillez entrer un numéro de téléphone';
                      }
                      if (phone.number.trim().length != 9) {
                        return 'Le numéro doit contenir 9 chiffres.';
                      }
                      return null;
                    },
                    onChanged: (phone) {
                      _countryDialCode = phone.countryCode;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    icon: Icons.lock,
                    obscureText: true,
                    validator: (value) => value == null || value.length < 6
                        ? 'Le mot de passe doit contenir au moins 6 caractères'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _confirmPasswordController,
                    label: 'Confirmer le mot de passe',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer le mot de passe';
                      }
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
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
                                  borderRadius: BorderRadius.circular(12.0))),
                          onPressed: _performSignUp,
                          child: const Text("S'inscrire",
                              style: TextStyle(color: Colors.white)),
                        ),
                  TextButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
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
