import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soifapp/users_page/planning_page.dart'; // Pour la classe Appointment
import 'package:soifapp/widgets/logout_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

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
  final ScrollController _timelineScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeAndLoadData();
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
    super.dispose();
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

    if (widget.coiffeurUserIdFromAdmin != null) {
      _coiffeurId = widget.coiffeurUserIdFromAdmin;
      _coiffeurName = widget.coiffeurNameFromAdmin ??
          'Coiffeur'; // Utiliser le nom fourni ou un défaut
    } else {
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
    }

    try {
      // Récupérer le nom du coiffeur seulement si non fourni par l'admin
      if (widget.coiffeurUserIdFromAdmin == null ||
          widget.coiffeurNameFromAdmin == null) {
        final profileResponse = await _supabase
            .from('profiles')
            .select('nom')
            .eq('id', _coiffeurId!)
            .single();
        _coiffeurName =
            profileResponse['nom'] as String? ?? _coiffeurName ?? 'Coiffeur';
      }
      // Si widget.coiffeurNameFromAdmin est fourni, _coiffeurName est déjà initialisé.

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
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  "Aucun rendez-vous pour ce jour.",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : _buildTimelineView(
                              appointmentsForSelectedDay, currentSelectedDay),
                    ),
                  ],
                ),
    );
  }

  // Fichier modifié pour intégrer un design de timeline moderne inspiré de `DailyTimelineItem`
// Reste compatible avec ton système actuel : CoiffeurHomePage + planning par heure avec ligne actuelle + événements stylés
// Voir `_buildTimelineSlot()` et `_buildTimelineView()` pour les changements principaux

// [Pas besoin de modifier le haut de fichier si ce n'est que les imports sont conservés]
// Tu peux coller l'intégralité du fichier de ta question ici, en remplacant les deux fonctions ci-dessous :

  Widget _buildTimelineView(List<Appointment> appointments, DateTime day) {
    const int startHour = 8;
    const int endHour = 20;
    const double slotHeight = 120.0;
    const double timeColumnWidth = 80.0;
    const double verticalPadding = 12.0;

    final now = tz.TZDateTime.now(_salonLocation!);
    final bool isToday =
        now.year == day.year && now.month == day.month && now.day == day.day;

    double? currentMinuteFraction;
    if (isToday && now.hour >= startHour && now.hour < endHour) {
      currentMinuteFraction = now.minute / 60.0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isToday &&
          currentMinuteFraction != null &&
          _timelineScrollController.hasClients &&
          _timelineScrollController.position.hasContentDimensions) {
        final double offset = ((now.hour - startHour) * slotHeight) +
            (slotHeight * currentMinuteFraction!) -
            100;
        final double maxScroll =
            _timelineScrollController.position.maxScrollExtent;
        final scrollTarget = offset.clamp(0.0, maxScroll);

        _timelineScrollController.animateTo(
          scrollTarget,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    List<Widget> timelineItems = [];
    for (int hour = startHour; hour < endHour; hour++) {
      final slotTime =
          tz.TZDateTime(_salonLocation!, day.year, day.month, day.day, hour);
      final appointmentsForHour = appointments
          .where((app) => app.startTime.hour == slotTime.hour)
          .toList();

      timelineItems.add(
        Stack(
          children: [
            _buildModernTimelineSlot(
                slotTime,
                appointmentsForHour,
                hour == startHour,
                hour == endHour - 1,
                isToday && hour == now.hour ? currentMinuteFraction : null),
          ],
        ),
      );
    }

    return ListView(
      controller: _timelineScrollController,
      padding: const EdgeInsets.only(bottom: 20.0),
      children: timelineItems,
    );
  }

  Widget _buildModernTimelineSlot(DateTime time, List<Appointment> events,
      bool isFirst, bool isLast, double? currentMinuteFraction) {
    final ThemeData theme = Theme.of(context);
    final timeLabel = DateFormat.Hm('fr_FR').format(time);

    final bool hasEvent = events.isNotEmpty;
    final Color indicatorColor =
        hasEvent ? theme.primaryColor : Colors.grey[400]!;
    final Color lineColor =
        hasEvent ? theme.primaryColor.withOpacity(0.6) : Colors.grey[300]!;

    return SizedBox(
      height: 120.0,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 80.0,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 2.0,
                        color: isFirst ? Colors.transparent : lineColor,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(hasEvent ? 8.0 : 4.0),
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        shape: BoxShape.circle,
                        boxShadow: hasEvent
                            ? [
                                BoxShadow(
                                    color: indicatorColor.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: Offset(0, 2))
                              ]
                            : null,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2.0,
                        color: isLast ? Colors.transparent : lineColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 16.0),
                  child: hasEvent
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: events
                              .map((event) => Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    color: theme.primaryColor.withOpacity(0.05),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.event,
                                                  size: 20,
                                                  color: theme.primaryColor),
                                              const SizedBox(width: 8),
                                              Text(
                                                event.serviceName,
                                                style:
                                                    theme.textTheme.titleMedium,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${DateFormat.Hm('fr_FR').format(event.startTime)} - ${DateFormat.Hm('fr_FR').format(event.endTime)}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        )
                      : Text(
                          'Libre à $timeLabel',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (currentMinuteFraction != null)
            Positioned(
              top: 120.0 * currentMinuteFraction,
              left: 80.0,
              right: 0,
              child: Container(
                height: 2,
                color: Colors.redAccent,
              ),
            ),
        ],
      ),
    );
  }
// Fin de la modification du fichier
}
