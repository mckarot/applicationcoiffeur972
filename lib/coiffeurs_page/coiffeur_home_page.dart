import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soifapp/appointments_timeline.dart';
import 'package:soifapp/users_page/planning_page.dart'; // Pour la classe Appointment
import 'package:soifapp/widgets/logout_button.dart'; // Pour la classe Appointment
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/timezone.dart' as tz; // Importer le package timezone

class CoiffeurHomePage extends StatefulWidget {
  final String? coiffeurUserIdFromAdmin;
  final String? coiffeurNameFromAdmin;

  const CoiffeurHomePage({
    super.key,
    this.coiffeurUserIdFromAdmin,
    this.coiffeurNameFromAdmin,
  });

  @override
  State<CoiffeurHomePage> createState() => _CoiffeurHomePageState();
}

class _CoiffeurHomePageState extends State<CoiffeurHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _coiffeurName;
  String? _coiffeurId;
  bool _isLoading = true;
  String? _errorMessage;

  CalendarFormat _calendarFormat =
      CalendarFormat.week; // Vue semaine par défaut
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Appointment>> _appointmentsByDay = {};
  tz.Location? _salonLocation;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    try {
      // Set the salon location to Martinique
      _salonLocation = tz.getLocation('America/Martinique');
      await _fetchCoiffeurDetailsAndAppointments();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur d'initialisation: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCoiffeurDetailsAndAppointments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.coiffeurUserIdFromAdmin != null) {
      _coiffeurId = widget.coiffeurUserIdFromAdmin;
      _coiffeurName = widget.coiffeurNameFromAdmin ??
          'Coiffeur'; // Utiliser le nom fourni ou un défaut
    } else {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _errorMessage = "Utilisateur non connecté.";
            _isLoading = false;
          });
        }
        return;
      }
      _coiffeurId = currentUser.uid;
    }

    try {
      // Récupérer le nom du coiffeur seulement si non fourni par l'admin
      if (widget.coiffeurUserIdFromAdmin == null ||
          widget.coiffeurNameFromAdmin == null) {
        final userDoc =
            await _firestore.collection('users').doc(_coiffeurId!).get();
        if (userDoc.exists) {
          _coiffeurName = userDoc.data()?['nom'] as String? ?? 'Coiffeur';
        } else {
          _coiffeurName = 'Coiffeur Inconnu';
        }
      }
      // Si widget.coiffeurNameFromAdmin est fourni, _coiffeurName est déjà initialisé.

      // Récupérer les rendez-vous du coiffeur
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('coiffeur_user_id', isEqualTo: _coiffeurId!)
          // Afficher les RDV confirmés et complétés
          .where('status', whereIn: ['confirmed', 'completed'])
          .orderBy('start_time')
          .get();

      final List<Appointment> loadedAppointments = [];
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final clientName = data['client_name'] as String? ?? 'Client inconnu';
        final serviceName = data['service_name'] as String? ?? 'Service inconnu';

        loadedAppointments.add(
          Appointment(
            id: doc.id,
            title: 'RDV $clientName - $serviceName',
            coiffeurName: _coiffeurName!,
            startTime: tz.TZDateTime.from(
                (data['start_time'] as Timestamp).toDate(), _salonLocation!),
            duration: Duration(
                minutes: data['duration_minutes'] as int? ?? 0),
          ),
        );
      }
      _groupAppointments(loadedAppointments);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print("Erreur chargement données coiffeur: $e");
        setState(() {
          _errorMessage = "Erreur de chargement des données: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  void _groupAppointments(List<Appointment> appointments) {
    _appointmentsByDay = {};
    for (var appointment in appointments) {
      DateTime dateKey = tz.TZDateTime(
          _salonLocation!,
          appointment.startTime.year,
          appointment.startTime.month,
          appointment.startTime.day);
      if (_appointmentsByDay[dateKey] == null) {
        _appointmentsByDay[dateKey] = [];
      }
      _appointmentsByDay[dateKey]!.add(appointment);
    }
  }

  List<Appointment> _getEventsForDay(DateTime day) {
    if (_salonLocation == null) return [];
    DateTime dateKey =
        tz.TZDateTime(_salonLocation!, day.year, day.month, day.day);
    return _appointmentsByDay[dateKey] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  // Annulation par le coiffeur
  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled_by_coiffeur',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous annulé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
        // Recharger les données pour mettre à jour l'UI
        await _fetchCoiffeurDetailsAndAppointments();
      }
    } catch (e) {
      if (mounted) {
        print("Erreur suppression RDV: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'annulation du rendez-vous: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAppointmentTap(Appointment appointment) {
    // La suppression est maintenant autorisée pour le coiffeur et l'administrateur.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annuler le rendez-vous ?'),
          content: Text( // Le titre contient déjà le nom du service
              'Voulez-vous vraiment supprimer ce rendez-vous ?\n\n${appointment.title}\n${DateFormat.yMMMMd('fr_FR').format(appointment.startTime)} à ${DateFormat.Hm('fr_FR').format(appointment.startTime)}'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Annuler le RDV'),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                _cancelAppointment(appointment.id);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSelectedDay = _selectedDay ?? _focusedDay;
    final appointmentsForSelectedDay = _getEventsForDay(currentSelectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(_coiffeurName == null
            ? (widget.coiffeurUserIdFromAdmin != null
                ? 'Planning Coiffeur'
                : 'Mon Planning')
            : 'Planning - $_coiffeurName'),
        // Ne pas afficher le bouton de déconnexion si l'admin consulte
        actions: widget.coiffeurUserIdFromAdmin == null
            ? const [LogoutButton()]
            : [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Bienvenue, ${_coiffeurName ?? 'Coiffeur'} !',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    TableCalendar<Appointment>(
                      locale: 'fr_FR',
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
                      eventLoader: _getEventsForDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: CalendarStyle(
                        // Styles adaptés de PlanningPage
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        // Styles adaptés de PlanningPage
                        formatButtonTextStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary),
                        formatButtonDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        titleTextStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      onDaySelected: _onDaySelected,
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "Rendez-vous pour le ${DateFormat.yMMMMd('fr_FR').format(currentSelectedDay)} :",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    Expanded(
                      child: appointmentsForSelectedDay.isEmpty
                          ? const Center(
                              child: Text("Aucun rendez-vous pour ce jour."))
                          : AppointmentsTimeline(
                              appointments: appointmentsForSelectedDay,
                              salonLocation: _salonLocation!,
                              onAppointmentTap: _handleAppointmentTap,
                            ),
                    ),
                  ],
                ),
    );
  }
}
