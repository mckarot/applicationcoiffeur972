import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleEntry {
  final String id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  ScheduleEntry(
      {required this.id, required this.startTime, required this.endTime});
}

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
  bool _isActif = true;
  bool _isLoading = false;
  bool _isFetchingInitialData = true;

  File? _selectedPhotoFile;
  String? _existingPhotoPath;
  String? _existingPublicUrl;
  final ImagePicker _picker = ImagePicker();

  final Map<int, List<ScheduleEntry>> _schedules = {
    1: [],
    2: [],
    3: [],
    4: [],
    5: [],
    6: [],
    7: [],
  };
  final List<String> _daysOfWeek = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final response = await _supabase
          .from('coiffeurs')
          .select()
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _specialitesController.text =
              (response['specialites'] as List<dynamic>?)?.join(', ') ?? '';
          _bioController.text = response['description_bio'] ?? '';
          _isActif = response['actif'] ?? true;
          _existingPhotoPath = response['photo_url'];

          if (_existingPhotoPath != null && _existingPhotoPath!.isNotEmpty) {
            _existingPublicUrl = _supabase.storage
                .from('photos.coiffeurs')
                .getPublicUrl(_existingPhotoPath!);
          }
        });

        await _fetchSchedules();
      }
    } catch (e) {
      print("Erreur chargement données coiffeur: $e");
      // Gérer l'erreur si nécessaire
    } finally {
      if (mounted) {
        setState(() => _isFetchingInitialData = false);
      }
    }
  }

  Future<void> _fetchSchedules() async {
    // No need for separate loading state, it's part of the initial load
    try {
      final response = await _supabase
          .from('coiffeur_work_schedules')
          .select()
          .eq('coiffeur_user_id', widget.userId);

      // Clear existing schedules before populating
      _schedules.forEach((key, value) => value.clear());

      for (var item in response) {
        final day = item['day_of_week'] as int;
        final startParts = (item['start_time'] as String).split(':');
        final endParts = (item['end_time'] as String).split(':');

        _schedules[day]?.add(ScheduleEntry(
          id: item['id'] as String,
          startTime: TimeOfDay(
              hour: int.parse(startParts[0]), minute: int.parse(startParts[1])),
          endTime: TimeOfDay(
              hour: int.parse(endParts[0]), minute: int.parse(endParts[1])),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erreur de chargement des horaires: ${e.toString()}"),
            backgroundColor: Colors.red));
      }
    }
  }

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

      String? finalPhotoPath = _existingPhotoPath;

      // Si une nouvelle photo a été sélectionnée, la téléverser
      if (_selectedPhotoFile != null) {
        final fileExtension = _selectedPhotoFile!.path.split('.').last;
        final uploadPath = 'public/${widget.userId}.$fileExtension';

        await _supabase.storage.from('photos.coiffeurs').upload(
              uploadPath,
              _selectedPhotoFile!,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: true),
            );
        finalPhotoPath = uploadPath;
      }

      // Utiliser upsert() au lieu de insert() pour gérer les cas où le coiffeur
      // existe déjà. Cela mettra à jour l'enregistrement existant ou en créera un nouveau.
      // C'est plus robuste et évite les erreurs de "duplicate key".
      await _supabase.from('coiffeurs').upsert({
        'user_id': widget.userId,
        'specialites': specialitesList,
        'description_bio': _bioController.text.trim(),
        'photo_url': finalPhotoPath,
        'actif': _isActif,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Coiffeur ${widget.userName} mis à jour avec succès!'),
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
              content: Text("Erreur lors de la mise à jour: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickPhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _selectedPhotoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _addSchedule(int dayOfWeek) async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'HEURE DE DÉBUT',
    );
    if (startTime == null) return;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      helpText: 'HEURE DE FIN',
    );
    if (endTime == null) return;

    final String startTimeStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
    final String endTimeStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';

    try {
      // On insère les données et on utilise .select() pour récupérer la ligne créée
      final newScheduleData = await _supabase
          .from('coiffeur_work_schedules')
          .insert({
            'coiffeur_user_id': widget.userId,
            'day_of_week': dayOfWeek,
            'start_time': startTimeStr,
            'end_time': endTimeStr,
          })
          .select()
          .single();

      if (mounted) {
        // On met à jour l'état local directement, sans avoir besoin de tout recharger.
        // C'est plus efficace et évite les bugs graphiques de re-rendu.
        setState(() {
          _schedules[dayOfWeek]?.add(ScheduleEntry(
            id: newScheduleData['id'] as String,
            startTime: startTime,
            endTime: endTime,
          ));
        });
      }
    } catch (e, stacktrace) {
      print("ERREUR LORS DE L'AJOUT D'UN HORAIRE: $e");
      print("STACKTRACE: $stacktrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erreur ajout horaire: ${e.toString()}"),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteSchedule(String scheduleId, int dayOfWeek) async {
    try {
      await _supabase
          .from('coiffeur_work_schedules')
          .delete()
          .eq('id', scheduleId);

      if (mounted) {
        // On met à jour l'état local directement.
        setState(() {
          _schedules[dayOfWeek]?.removeWhere((entry) => entry.id == scheduleId);
        });
      }
    } catch (e, stacktrace) {
      print("ERREUR LORS DE LA SUPPRESSION D'UN HORAIRE: $e");
      print("STACKTRACE: $stacktrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erreur suppression horaire: ${e.toString()}"),
            backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildScheduleManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 40, thickness: 1),
        Text(
          "Horaires de travail",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _daysOfWeek.length,
          itemBuilder: (context, index) {
            final dayIndex = index + 1;
            final dayName = _daysOfWeek[index];
            final schedulesForDay = _schedules[dayIndex]!;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () => _addSchedule(dayIndex),
                            tooltip: 'Ajouter une plage horaire'),
                      ],
                    ),
                    if (schedulesForDay.isEmpty)
                      const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('Aucun horaire défini pour ce jour.',
                              style: TextStyle(fontStyle: FontStyle.italic)))
                    else
                      ...schedulesForDay.map((entry) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                              '${entry.startTime.format(context)} - ${entry.endTime.format(context)}'),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () =>
                                  _deleteSchedule(entry.id, dayIndex)),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_isFetchingInitialData)
                const Center(child: CircularProgressIndicator())
              else ...[
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
                const SizedBox(height: 24),
                Text("Photo de profil (optionnel)",
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7.0),
                          child: _selectedPhotoFile != null
                              ? Image.file(_selectedPhotoFile!,
                                  fit: BoxFit.cover)
                              : (_existingPublicUrl != null
                                  ? Image.network(_existingPublicUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) =>
                                          const Icon(Icons.person, size: 60))
                                  : const Icon(Icons.person_outline,
                                      size: 60, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image_search_outlined),
                        label: Text(_selectedPhotoFile != null ||
                                _existingPublicUrl != null
                            ? 'Changer la photo'
                            : 'Choisir une photo'),
                        onPressed: _pickPhoto,
                      ),
                    ],
                  ),
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
                          label: const Text('Mettre à jour le Coiffeur'),
                          onPressed: _activateCoiffeur,
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15)),
                        ),
                ),
                _buildScheduleManager(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
