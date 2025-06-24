import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCoiffeurs();
    initializeDateFormatting('fr_FR', null);
  }

  Future<void> _fetchCoiffeurs() async {
    final response = await _supabaseClient
        .from('profiles')
        .select('id, nom')
        .eq('role', 'coiffeur');
    setState(() {
      _coiffeurs = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _fetchAbsences() async {
    if (_selectedCoiffeurId == null) return;
    final response = await _supabaseClient
        .from('coiffeur_absences')
        .select('id, start_time, end_time, reason')
        .eq('coiffeur_user_id', _selectedCoiffeurId!)
        .order('start_time', ascending: true);
    setState(() {
      _absences = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _addAbsence() async {
    if (_selectedCoiffeurId == null || _startDate == null || _endDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir tous les champs.')));
      return;
    }

    // Ajout d'une vérification de la cohérence des dates
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
      await _supabaseClient.from('coiffeur_absences').insert({
        'coiffeur_user_id': _selectedCoiffeurId,
        'start_time': _startDate!.toIso8601String(),
        'end_time': _endDate!.toIso8601String(),
        'reason': _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      });

      if (!mounted) return;

      _fetchAbsences(); // Rafraîchir la liste des absences
      _clearAbsenceFields();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absence ajoutée avec succès.')));
    } catch (e) {
      print(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de l\'absence.')));
    } finally {
      setState(() {
        _isLoading = false;
      });
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

      _fetchAbsences(); // Rafraîchir la liste des absences
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absence supprimée avec succès.')));
    } catch (e) {
      print(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la suppression de l\'absence.')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearAbsenceFields() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les absences des coiffeurs'),
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
                  value: coiffeur['id'],
                  child: Text(coiffeur['nom']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCoiffeurId = value;
                  _fetchAbsences();
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate:
                            _startDate ?? DateTime.now(), // Use current value
                        firstDate: DateTime.now().subtract(const Duration(
                            days:
                                365)), // Allow past dates for historical absences
                        lastDate: DateTime(2100),
                        locale:
                            const Locale('fr', 'FR'), // Ensure French locale
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _startDate = pickedDate;
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
                        initialDate: _endDate ??
                            _startDate ??
                            DateTime.now(), // Use current value or start date
                        firstDate: _startDate ??
                            DateTime.now().subtract(const Duration(
                                days: 365)), // Cannot be before start date
                        lastDate: DateTime(2100),
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
                  : const Text('Ajouter une absence'),
            ),
            const SizedBox(height: 40),
            const Text('Absences planifiées:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _absences.isEmpty
                ? const Text('Aucune absence planifiée pour ce coiffeur.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _absences.length,
                    itemBuilder: (context, index) {
                      final absence = _absences[index];
                      final DateTime startTime =
                          DateTime.parse(absence['start_time'] as String);
                      final DateTime endTime =
                          DateTime.parse(absence['end_time'] as String);
                      return Card(
                        child: ListTile(
                          title: Text(
                              'Du ${DateFormat('dd/MM/yyyy', 'fr_FR').format(startTime)} au ${DateFormat('dd/MM/yyyy', 'fr_FR').format(endTime)}'),
                          subtitle: Text(
                              absence['reason'] ?? 'Aucune raison spécifiée'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteAbsence(absence['id']),
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
