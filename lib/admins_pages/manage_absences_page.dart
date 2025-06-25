import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class ManageAbsencesPage extends StatefulWidget {
  const ManageAbsencesPage({Key? key}) : super(key: key);

  @override
  ManageAbsencesPageState createState() => ManageAbsencesPageState();
}

class ManageAbsencesPageState extends State<ManageAbsencesPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  List<Map<String, dynamic>> _coiffeurs = [];
  String? _selectedCoiffeurId;
  List<Map<String, dynamic>> _absences = [];
  DateTime? _startDate;
  DateTime? _endDate;
  tz.Location? _salonLocation;
  // Un seul sélecteur de période
  String _selectedPeriod = 'Journée complète';
  final List<String> _dayPeriods = const [
    'Journée complète',
    'Matin',
    'Après-midi'
  ];
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSalonLocation();
    _fetchCoiffeurs();
    initializeDateFormatting('fr_FR', null);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _initializeSalonLocation() async {
    // Il est préférable d'initialiser les fuseaux horaires une seule fois dans main.dart
    // mais nous le faisons ici par sécurité.
    tz_data.initializeTimeZones();
    try {
      _salonLocation = tz.getLocation('America/Martinique');
    } catch (e) {
      print(
          "Erreur initialisation fuseau horaire salon (ManageAbsencesPage): $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Erreur de configuration du fuseau horaire. L'ajout d'absence pourrait être incorrect.")),
        );
      }
    }
  }

  Future<void> _fetchCoiffeurs() async {
    final response = await _supabaseClient
        .from('profiles')
        .select('id, nom')
        .eq('role', 'coiffeur');
    if (!mounted) return;
    setState(() {
      _coiffeurs = List<Map<String, dynamic>>.from(response as List);
    });
  }

  Future<void> _fetchAbsences() async {
    if (_selectedCoiffeurId == null) return;
    final response = await _supabaseClient
        .from('coiffeur_absences')
        .select('id, start_time, end_time, reason')
        .eq('coiffeur_user_id', _selectedCoiffeurId!)
        .order('start_time', ascending: true);
    if (!mounted) return;
    setState(() {
      _absences = List<Map<String, dynamic>>.from(response as List);
    });
  }

  tz.TZDateTime _getDateTimeWithPeriod(DateTime date, String period,
      bool isStartOfPeriod, tz.Location location) {
    switch (period) {
      case 'Matin':
        return tz.TZDateTime(location, date.year, date.month, date.day,
            isStartOfPeriod ? 9 : 12, 0);
      case 'Après-midi':
        return tz.TZDateTime(location, date.year, date.month, date.day,
            isStartOfPeriod ? 13 : 19, 0);
      case 'Journée complète':
      default:
        return tz.TZDateTime(location, date.year, date.month, date.day,
            isStartOfPeriod ? 9 : 19, 0);
    }
  }

  Future<void> _addAbsence() async {
    if (_selectedCoiffeurId == null || _startDate == null || _endDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir tous les champs.')));
      return;
    }

    if (_salonLocation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Erreur de fuseau horaire. Impossible d\'ajouter l\'absence.')));
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('La date de fin ne peut pas être avant la date de début.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer une liste d'absences pour chaque jour de la plage sélectionnée
      final List<Map<String, dynamic>> absencesToInsert = [];
      for (var day = 0;
          day <= _endDate!.difference(_startDate!).inDays;
          day++) {
        final currentDate = _startDate!.add(Duration(days: day));

        final tz.TZDateTime finalStartDate = _getDateTimeWithPeriod(
            currentDate, _selectedPeriod, true, _salonLocation!);
        final tz.TZDateTime finalEndDate = _getDateTimeWithPeriod(
            currentDate, _selectedPeriod, false, _salonLocation!);

        absencesToInsert.add({
          'coiffeur_user_id': _selectedCoiffeurId,
          'start_time': finalStartDate.toIso8601String(),
          'end_time': finalEndDate.toIso8601String(),
          'reason': _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
        });
      }

      // Insérer toutes les absences en une seule requête
      await _supabaseClient.from('coiffeur_absences').insert(absencesToInsert);

      if (!mounted) return;

      _fetchAbsences();
      _clearAbsenceFields();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absence(s) ajoutée(s) avec succès.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de l\'absence: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAbsence(String absenceId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _supabaseClient
          .from('coiffeur_absences')
          .delete()
          .eq('id', absenceId);

      if (!mounted) return;

      _fetchAbsences();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absence supprimée avec succès.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la suppression de l\'absence: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearAbsenceFields() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
      _selectedPeriod = 'Journée complète';
    });
  }

  String _formatAbsencePeriod(tz.TZDateTime start, tz.TZDateTime end) {
    final DateFormat dayFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    final DateFormat timeFormat = DateFormat.Hm('fr_FR');

    final String startDay = dayFormat.format(start);
    final String endDay = dayFormat.format(end);

    final String formattedStartTime = timeFormat.format(start);
    final String formattedEndTime = timeFormat.format(end);

    if (startDay == endDay) {
      if (start.hour == 9 && end.hour == 12) {
        return 'Le $startDay (Matin : $formattedStartTime - $formattedEndTime)';
      }
      if (start.hour == 13 && end.hour == 19) {
        return 'Le $startDay (Après-midi : $formattedStartTime - $formattedEndTime)';
      }
      if (start.hour == 9 && end.hour == 19) {
        return 'Le $startDay (Journée complète : $formattedStartTime - $formattedEndTime)';
      }
      return 'Le $startDay de $formattedStartTime à $formattedEndTime';
    } else {
      return 'Du ${dayFormat.format(start)} (${timeFormat.format(start)}) au ${dayFormat.format(end)} (${timeFormat.format(end)})';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les absences'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration:
                  const InputDecoration(labelText: 'Sélectionner un coiffeur'),
              value: _selectedCoiffeurId,
              items: _coiffeurs.map((coiffeur) {
                return DropdownMenuItem<String>(
                  value: coiffeur['id'] as String,
                  child: Text(coiffeur['nom'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCoiffeurId = value;
                  _absences.clear();
                  if (value != null) {
                    _fetchAbsences();
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime(2100),
                        locale: const Locale('fr', 'FR'),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _startDate = pickedDate;
                          if (_endDate == null ||
                              _endDate!.isBefore(pickedDate)) {
                            _endDate = pickedDate;
                          }
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de début',
                        hintText: 'Sélectionner une date',
                      ),
                      child: Text(_startDate != null
                          ? DateFormat('dd/MM/yyyy', 'fr_FR')
                              .format(_startDate!)
                          : 'Non sélectionnée'),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? _startDate ?? DateTime.now(),
                        firstDate: _startDate ??
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime(2100),
                        locale: const Locale('fr', 'FR'),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _endDate = pickedDate;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de fin',
                        hintText: 'Sélectionner une date',
                      ),
                      child: Text(_endDate != null
                          ? DateFormat('dd/MM/yyyy', 'fr_FR').format(_endDate!)
                          : 'Non sélectionnée'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Le sélecteur de période unique
            DropdownButtonFormField<String>(
              decoration:
                  const InputDecoration(labelText: 'Période d\'absence'),
              value: _selectedPeriod,
              items: _dayPeriods.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPeriod = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _addAbsence,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Ajouter absence(s)'),
            ),
            const SizedBox(height: 40),
            const Text('Absences planifiées:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _absences.isEmpty
                    ? const Text('Aucune absence planifiée pour ce coiffeur.')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _absences.length,
                        itemBuilder: (context, index) {
                          final absence = _absences[index];
                          if (_salonLocation == null) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                title: const Text("Erreur de fuseau horaire"),
                                subtitle: Text(
                                    "Impossible d'afficher l'absence pour ${absence['start_time']}"),
                              ),
                            );
                          }
                          final tz.TZDateTime startTime = tz.TZDateTime.from(
                              DateTime.parse(absence['start_time'] as String),
                              _salonLocation!);
                          final tz.TZDateTime endTime = tz.TZDateTime.from(
                              DateTime.parse(absence['end_time'] as String),
                              _salonLocation!);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text(
                                  _formatAbsencePeriod(startTime, endTime)),
                              subtitle: Text(absence['reason'] as String? ??
                                  'Aucune raison spécifiée'),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteAbsence(absence['id'] as String),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
