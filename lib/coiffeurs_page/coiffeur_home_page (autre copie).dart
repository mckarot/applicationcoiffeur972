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

  Widget _buildTimelineView(List<Appointment> appointments, DateTime day) {
    const int startHour = 8;
    const int endHour = 20;

    final now = tz.TZDateTime.now(_salonLocation!);
    final bool isToday =
        now.year == day.year && now.month == day.month && now.day == day.day;

    const double slotHeight = 70.0;
    const double circleIndicatorDiameter = 10.0;
    const double listViewHorizontalPadding = 16.0;
    const double listViewVerticalPadding = 12.0;
    const double timeColumnWidth = 65.0;

    double? currentTimeLineOffset;
    if (isToday && now.hour >= startHour && now.hour < endHour) {
      final minutesIntoTimeline = (now.hour - startHour) * 60 + now.minute;
      currentTimeLineOffset = minutesIntoTimeline * slotHeight / 60;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isToday &&
          currentTimeLineOffset != null &&
          _timelineScrollController.hasClients) {
        final double scrollTarget = (currentTimeLineOffset - 100)
            .clamp(0, _timelineScrollController.position.maxScrollExtent);
        _timelineScrollController.animateTo(
          scrollTarget,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });

    List<Widget> timelineSlots = [];
    for (int hour = startHour; hour < endHour; hour++) {
      final slotTime =
          tz.TZDateTime(_salonLocation!, day.year, day.month, day.day, hour);
      final appointmentsInSlot = appointments
          .where((app) => app.startTime.hour == hour)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      timelineSlots
          .add(_buildTimelineSlot(slotTime, appointmentsInSlot, context));
    }

    return Stack(
      children: [
        ListView(
          controller: _timelineScrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: listViewHorizontalPadding,
            vertical: listViewVerticalPadding,
          ),
          children: timelineSlots,
        ),
        if (isToday && currentTimeLineOffset != null)
          Positioned(
            top: currentTimeLineOffset +
                listViewVerticalPadding -
                (circleIndicatorDiameter / 2),
            left: listViewHorizontalPadding +
                timeColumnWidth -
                (circleIndicatorDiameter / 2),
            right: listViewHorizontalPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: circleIndicatorDiameter,
                  height: circleIndicatorDiameter,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 2,
                    color: Colors.redAccent.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineSlot(tz.TZDateTime slotTime,
      List<Appointment> appointments, BuildContext context) {
    final timeFormatter = DateFormat.Hm('fr_FR');

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 8.0), // Espace entre les slots horaires
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonne de l'heure
          Container(
            width: 65, // Un peu plus de largeur pour l'heure
            padding: const EdgeInsets.only(
                top: 12.0,
                right:
                    8.0), // Pour aligner avec le haut de la première carte et espacer
            child: Text(
              timeFormatter.format(slotTime),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600, // Moins gras que bold
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Colonne des rendez-vous
          Expanded(
            child: appointments.isEmpty
                ? Container(
                    // Envelopper avec un Container pour appliquer les contraintes
                    constraints:
                        const BoxConstraints(minHeight: 50), // Hauteur minimale
                    child: Padding(
                      // Le Padding est maintenant un enfant du Container
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      child: Text(
                        'Libre',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: appointments.map((appointment) {
                      final clientNameDisplay = appointment.title
                                  .startsWith("RDV ") &&
                              appointment.title.contains(" - ")
                          ? appointment.title
                              .substring(4, appointment.title.indexOf(" - "))
                          : "Client";
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: 10.0), // Espace entre les cartes de RDV
                        child: Card(
                          elevation: 1.5,
                          margin: EdgeInsets
                              .zero, // La marge est gérée par le Padding parent
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            // side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4))
                          ),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${appointment.serviceName} pour $clientNameDisplay',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${timeFormatter.format(appointment.startTime)} - ${timeFormatter.format(appointment.endTime)}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
