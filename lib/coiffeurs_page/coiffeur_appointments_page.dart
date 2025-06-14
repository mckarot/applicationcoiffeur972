import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soifapp/users_page/planning_page.dart'; // Pour la classe Appointment
import 'package:supabase_flutter/supabase_flutter.dart'; // Importer Supabase
import 'package:timezone/timezone.dart' as tz; // Importer le package timezone

class CoiffeurAppointmentsPage extends StatefulWidget {
  final String coiffeurUserId;
  final String coiffeurName;

  const CoiffeurAppointmentsPage(
      {super.key, required this.coiffeurUserId, required this.coiffeurName});

  @override
  State<CoiffeurAppointmentsPage> createState() =>
      _CoiffeurAppointmentsPageState();
}

class _CoiffeurAppointmentsPageState extends State<CoiffeurAppointmentsPage> {
  List<Appointment> _coiffeurAppointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  tz.Location? _salonLocation; // Pour stocker la localisation du salon

  @override
  void initState() {
    super.initState();
    _initializeSalonLocationAndLoadAppointments();
  }

  Future<void> _initializeSalonLocationAndLoadAppointments() async {
    // Assurez-vous que initializeTimeZones() a été appelé dans main.dart
    // Définissez ici le fuseau horaire de votre salon
    try {
      // Vous pouvez rendre ce nom de fuseau horaire configurable si nécessaire
      _salonLocation = tz.getLocation('Europe/Paris');
      await _loadAppointments();
    } catch (e) {
      print(
          "Erreur lors de l'initialisation du fuseau horaire du salon (coiffeur): $e");
      if (mounted)
        setState(
            () => _errorMessage = "Erreur de configuration du fuseau horaire.");
    }
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_salonLocation == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Fuseau horaire du salon non initialisé.";
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('appointments')
          // Jointure pour récupérer le nom du client depuis la table profiles
          .select(
              '*, client_profile:profiles!appointments_client_user_id_fkey(nom)')
          .eq('coiffeur_user_id',
              widget.coiffeurUserId) // Filtrer par ID utilisateur du coiffeur
          .gte(
              'start_time',
              DateTime.now()
                  .subtract(const Duration(hours: 1))
                  .toIso8601String()) // RDV à venir ou très récents
          .order('start_time', ascending: true);

      if (!mounted) return;

      final List<Appointment> loadedAppointments = [];
      for (var item in response) {
        String clientName = 'Client inconnu';
        if (item['client_profile'] != null &&
            (item['client_profile'] as Map).containsKey('nom')) {
          clientName = item['client_profile']['nom'] as String? ?? clientName;
        } else {
          print(
              "Profil client non trouvé ou nom manquant pour RDV ID: ${item['id']}");
        }
        final serviceName = item['service_name'] as String;

        loadedAppointments.add(
          Appointment(
            // Le champ 'title' de la classe Appointment n'est pas directement dans la table.
            // Nous pouvons le construire ou le rendre optionnel dans la classe Appointment.
            // Pour l'instant, construisons un titre simple.
            title: 'RDV $clientName - $serviceName',
            serviceName: serviceName,
            coiffeurName: widget
                .coiffeurName, // Utiliser le nom du coiffeur passé en widget
            // Convertir l'heure UTC de la DB en TZDateTime dans le fuseau du salon
            startTime: tz.TZDateTime.from(
                DateTime.parse(
                    item['start_time'] as String), // Ceci est une heure UTC
                _salonLocation!),
            duration: Duration(minutes: item['duration_minutes'] as int),
          ),
        );
      }

      setState(() {
        _coiffeurAppointments = loadedAppointments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print("Erreur lors du chargement des RDV du coiffeur: $e");
      setState(() {
        _isLoading = false;
        _errorMessage =
            "Erreur lors du chargement des rendez-vous: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Rendez-vous - ${widget.coiffeurName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ))
              : _coiffeurAppointments.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun rendez-vous à venir pour ${widget.coiffeurName}.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAppointments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _coiffeurAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _coiffeurAppointments[index];
                          // Extraire le nom du client du titre (méthode simple, pourrait être améliorée)
                          final clientNameDisplay =
                              appointment.title.startsWith("RDV ") &&
                                      appointment.title.contains(" - ")
                                  ? appointment.title.substring(
                                      4, appointment.title.indexOf(" - "))
                                  : "Client";

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: Icon(Icons.event_note_rounded,
                                  color: Theme.of(context).colorScheme.primary),
                              title: Text(appointment.serviceName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  "${DateFormat.MMMMEEEEd('fr_FR').format(appointment.startTime)}\n${DateFormat.Hm('fr_FR').format(appointment.startTime)} - ${DateFormat.Hm('fr_FR').format(appointment.endTime)}\nClient: $clientNameDisplay"),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
