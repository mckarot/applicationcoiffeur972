import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soifapp/users_page/planning_page.dart'; // Pour la classe Appointment
import 'package:soifapp/widgets/logout_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

class CoiffeurHomePage extends StatefulWidget {
  const CoiffeurHomePage({super.key});

  @override
  State<CoiffeurHomePage> createState() => _CoiffeurHomePageState();
}

class _CoiffeurHomePageState extends State<CoiffeurHomePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
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
      _salonLocation = tz.getLocation('Europe/Paris'); // Ajustez si nécessaire
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

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _errorMessage = "Utilisateur non connecté.";
          _isLoading = false;
        });
      }
      return;
    }
    _coiffeurId = currentUser.id;

    try {
      // Récupérer le nom du coiffeur
      final profileResponse = await _supabase
          .from('profiles')
          .select('nom')
          .eq('id', _coiffeurId!)
          .single();
      _coiffeurName = profileResponse['nom'] as String? ?? 'Coiffeur';

      // Récupérer les rendez-vous du coiffeur
      final appointmentsResponse = await _supabase
          .from('appointments')
          .select(
              '*, client_profile:profiles!appointments_client_user_id_fkey(nom)')
          .eq('coiffeur_user_id', _coiffeurId!)
          .order('start_time', ascending: true);

      final List<Appointment> loadedAppointments = [];
      for (var item in appointmentsResponse) {
        final clientName = (item['client_profile'] != null &&
                (item['client_profile'] as Map).containsKey('nom'))
            ? item['client_profile']['nom'] as String? ?? 'Client inconnu'
            : 'Client inconnu';
        final serviceName =
            item['service_name'] as String? ?? 'Service inconnu';

        loadedAppointments.add(
          Appointment(
            title: 'RDV $clientName - $serviceName',
            serviceName: serviceName,
            coiffeurName: _coiffeurName!, // Le nom du coiffeur actuel
            startTime: tz.TZDateTime.from(
                DateTime.parse(item['start_time'] as String), _salonLocation!),
            duration: Duration(minutes: item['duration_minutes'] as int),
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

  @override
  Widget build(BuildContext context) {
    final currentSelectedDay = _selectedDay ?? _focusedDay;
    final appointmentsForSelectedDay = _getEventsForDay(currentSelectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(_coiffeurName == null
            ? 'Espace Coiffeur'
            : 'Planning - $_coiffeurName'),
        actions: const [LogoutButton()],
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
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: appointmentsForSelectedDay.length,
                              itemBuilder: (context, index) {
                                final appointment =
                                    appointmentsForSelectedDay[index];
                                // Extraire le nom du client du titre
                                final clientNameDisplay =
                                    appointment.title.startsWith("RDV ") &&
                                            appointment.title.contains(" - ")
                                        ? appointment.title.substring(
                                            4, appointment.title.indexOf(" - "))
                                        : "Client";

                                return Card(
                                  child: ListTile(
                                    leading: Icon(Icons.person_pin_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                    title: Text(
                                        '${appointment.serviceName} pour $clientNameDisplay'),
                                    subtitle: Text(
                                        '${DateFormat.Hm('fr_FR').format(appointment.startTime)} - ${DateFormat.Hm('fr_FR').format(appointment.endTime)}'),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
