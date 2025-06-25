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
      cursorColor: Theme.of(context).colorScheme.primary,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        hintText: hint,
        hintStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(Icons.person_add_alt_1,
                        size: 80, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Créer un compte',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inscrivez-vous pour accéder à nos services',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildInputField(
                      controller: _nameController,
                      label: 'Nom complet',
                      icon: Icons.person_outline,
                      hint: 'Entrez votre nom',
                      validator: (value) => value == null || value.isEmpty
                          ? 'Veuillez entrer votre nom'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
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
                        labelStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.error, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.error, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      initialCountryCode:
                          'MQ', // Pays initial défini sur Martinique
                      disableLengthCheck:
                          true, // Désactive la validation de longueur par défaut du package
                      showDropdownIcon: true,
                      dropdownIcon: Icon(Icons.arrow_drop_down,
                          color: theme.colorScheme.primary),
                      dropdownTextStyle:
                          TextStyle(color: theme.colorScheme.onSurface),
                      style: TextStyle(color: theme.colorScheme.onSurface),
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
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) => value == null || value.length < 6
                          ? 'Le mot de passe doit contenir au moins 6 caractères'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _confirmPasswordController,
                      label: 'Confirmer le mot de passe',
                      icon: Icons.lock_reset,
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
                    const SizedBox(height: 32),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                textStyle: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0))),
                            onPressed: _performSignUp,
                            child: const Text("S'inscrire"),
                          ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Déjà un compte ?",
                            style: theme.textTheme.bodyMedium),
                        TextButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text('Se connecter',
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold)),
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
