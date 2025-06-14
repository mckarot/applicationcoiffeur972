import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivateCoiffeurPage extends StatefulWidget {
  final String userId;
  final String userName;

  const ActivateCoiffeurPage(
      {super.key, required this.userId, required this.userName});

  @override
  State<ActivateCoiffeurPage> createState() => _ActivateCoiffeurPageState();
}

class _ActivateCoiffeurPageState extends State<ActivateCoiffeurPage> {
  final _formKey = GlobalKey<FormState>();
  final _specialitesController = TextEditingController();
  final _bioController = TextEditingController();
  final _photoUrlController =
      TextEditingController(); // Pour l'instant, URL manuelle
  bool _isActif = true;
  bool _isLoading = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _activateCoiffeur() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Convertir les spécialités en liste (séparées par des virgules par exemple)
      final List<String> specialitesList = _specialitesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await _supabase.from('coiffeurs').insert({
        'user_id': widget.userId,
        'specialites': specialitesList,
        'description_bio': _bioController.text.trim(),
        'photo_url': _photoUrlController.text.trim().isEmpty
            ? null
            : _photoUrlController.text.trim(),
        'actif': _isActif,
        // 'horaires_disponibilite_id': null, // Si vous avez ce champ, gérez-le
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${widget.userName} activé avec succès!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Retourne true pour indiquer un succès
      }
    } catch (e, stacktrace) {
      // Ajout de stacktrace ici
      if (mounted) {
        print("ERREUR DETECTEE LORS DE L'ACTIVATION: $e"); // Afficher l'erreur
        print("STACKTRACE: $stacktrace"); // Afficher la pile d'appels
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erreur lors de l'activation: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Activer ${widget.userName}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("Coiffeur: ${widget.userName}",
                  style: Theme.of(context).textTheme.titleLarge),
              Text("ID: ${widget.userId}",
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              TextFormField(
                controller: _specialitesController,
                decoration: const InputDecoration(
                    labelText: 'Spécialités (séparées par des virgules)',
                    border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer au moins une spécialité.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                    labelText: 'Description / Bio',
                    border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _photoUrlController,
                decoration: const InputDecoration(
                    labelText: 'URL de la photo (optionnel)',
                    hintText: 'ex: chemin/vers/photo.jpg dans le bucket',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Actif'),
                value: _isActif,
                onChanged: (bool value) {
                  setState(() {
                    _isActif = value;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 30),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Activer le Coiffeur'),
                        onPressed: _activateCoiffeur,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
