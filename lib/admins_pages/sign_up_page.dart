import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String _countryDialCode = ''; // Pour stocker le code du pays
  final SupabaseClient _supabase = Supabase.instance.client;

  final List<String> _roles = ['user', 'coiffeur', 'admin'];
  String _selectedRole = 'user';

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

// Si signUp réussit sans exception, res.user ne devrait pas être null.

        if (res.user == null) {
// Cas inattendu si aucune AuthException n'a été levée.

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Erreur d\'inscription: utilisateur non retourné après la création.')),
            );
          }

          return; // Sortir tôt pour éviter d'autres erreurs
        }

        try {
          final String localPhone = _phoneController.text.trim();
          final String? finalPhoneNumber =
              localPhone.isNotEmpty ? '$_countryDialCode$localPhone' : null;

          if (mounted) {
            await _supabase.from('profiles').insert({
              'id': res.user!.id,
              'nom': _nameController.text.trim(),
              'telephone': finalPhoneNumber,
              'role': _selectedRole, // Utilise le rôle choisi
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
              Navigator.pop(context); // Retour à la page de connexion
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
    final theme = Theme.of(context);
    return TextFormField(
      cursorColor: theme.colorScheme.primary,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        hintText: hint,
        hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
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
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(color: theme.colorScheme.onSurface),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Créer un compte'),
      ),
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
              padding: const EdgeInsets.all(20.0),
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
                      'Créer un nouveau profil pour un utilisateur',
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
                      hint: 'Entrez un nom',
                      validator: (value) => value == null || value.isEmpty
                          ? 'Veuillez entrer votre nom'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      hint: 'entrez_un_email@example.com',
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
                      initialCountryCode: 'MQ',
                      disableLengthCheck: true,
                      showDropdownIcon: true,
                      dropdownIcon: Icon(Icons.arrow_drop_down,
                          color: theme.colorScheme.primary),
                      dropdownTextStyle:
                          TextStyle(color: theme.colorScheme.onSurface),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (phone) {
                        // Le champ est optionnel, donc on ne valide que s'il n'est pas vide
                        if (phone != null &&
                            phone.number.trim().isNotEmpty &&
                            phone.number.trim().length != 9) {
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
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Rôle de l\'utilisateur',
                        labelStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant),
                        prefixIcon: Icon(Icons.manage_accounts_outlined,
                            color: theme.colorScheme.primary),
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
                      ),
                      dropdownColor: theme.colorScheme.surfaceContainer,
                      items: _roles
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(
                                    role[0].toUpperCase() + role.substring(1)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
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
                            child: const Text("Créer l'utilisateur"),
                          ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text('Annuler',
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold)),
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
