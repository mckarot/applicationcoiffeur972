import 'package:flutter/material.dart';
import 'package:soifapp/users_page/booking_page.dart';
import 'package:soifapp/widgets/logout_button.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:soifapp/users_page/salon_location_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:soifapp/widgets/modern_bottom_nav_bar.dart';
import 'package:soifapp/users_page/settings_page.dart';

// Classe simple pour représenter un rendez-vous
class Appointment {
  final String id;
  final String title;
  final String coiffeurName;
  final tz.TZDateTime startTime; // Utiliser TZDateTime
  final Duration duration;

  Appointment({
    required this.id,
    required this.title,
    required this.coiffeurName,
    required this.startTime,
    required this.duration,
  });

  tz.TZDateTime get endTime => tz.TZDateTime.fromMillisecondsSinceEpoch(
      startTime.location,
      startTime.millisecondsSinceEpoch + duration.inMilliseconds);

  factory Appointment.fromFirestore(
      QueryDocumentSnapshot doc, tz.Location location) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      title: data['service_name'] as String? ?? 'Service inconnu',
      coiffeurName: data['coiffeur_name'] as String? ?? 'Coiffeur inconnu',
      startTime: tz.TZDateTime.from(
        (data['start_time'] as Timestamp).toDate(),
        location,
      ),
      duration: Duration(minutes: data['duration_minutes'] as int? ?? 0),
    );
  }
}

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Appointment>> _events = {};
  bool _isLoading = true;
  String? _errorMessage;
  tz.Location? _salonLocation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeSalonLocationAndLoadAppointments();
  }

  Future<void> _initializeSalonLocationAndLoadAppointments() async {
    try {
      _salonLocation = tz.getLocation('America/Martinique');
      await _loadClientAppointments();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Erreur de configuration du fuseau horaire.";
      });
    }
  }

  Future<void> _loadClientAppointments() async {
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
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("Utilisateur non connecté.");
      }

      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('client_user_id', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'confirmed')
          .orderBy('start_time')
          .get();

      if (!mounted) return;

      final loadedAppointments = appointmentsSnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc, _salonLocation!))
          .toList();

      _groupAppointments(loadedAppointments);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Erreur de chargement des rendez-vous.";
      });
    }
  }

  void _groupAppointments([List<Appointment> appointments = const []]) {
    _events = {};
    for (var appointment in appointments) {
      DateTime dateKey = tz.TZDateTime(
          _salonLocation!,
          appointment.startTime.year,
          appointment.startTime.month,
          appointment.startTime.day);
      if (_events[dateKey] == null) {
        _events[dateKey] = [];
      }
      _events[dateKey]!.add(appointment);
    }
  }

  List<Appointment> _getEventsForDay(DateTime day) {
    if (_salonLocation == null) return [];
    DateTime dateKey =
        tz.TZDateTime(_salonLocation!, day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'cancelled_by_client',
        'updated_at': FieldValue.serverTimestamp()
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous annulé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadClientAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l annulation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAppointmentTap(Appointment appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Annuler le rendez-vous ?'),
          content: Text(
              'Voulez-vous vraiment annuler ce rendez-vous ?\n\n${appointment.title} avec ${appointment.coiffeurName}\n${DateFormat.yMMMMd('fr_FR').format(appointment.startTime)} à ${DateFormat.Hm('fr_FR').format(appointment.startTime)}'),
          actions: <Widget>[
            TextButton(
              child: const Text('Retour'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text(
                'Confirmer l\'annulation',
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelAppointment(appointment.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const BookingPage()));
        break;
      case 2:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const SalonLocationPage()));
        break;
      case 3:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const SettingsPage()));
        break;
      default:
        setState(() {
          _currentIndex = index;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.98),
      appBar: AppBar(
        title: const Text('Mon Planning',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadClientAppointments,
          tooltip: 'Rafraîchir',
        ),
        actions: const [LogoutButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktopLayout();
          } else {
            return _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _buildCalendarAndAppointments();
          }
        },
      ),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final currentSelectedDay = _selectedDay ?? _focusedDay;
    final appointmentsForSelectedDay = _getEventsForDay(currentSelectedDay);

    return Row(
      children: [
        // Calendrier à gauche
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Calendrier",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: _buildCalendar(),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Séparateur
        const VerticalDivider(
          width: 1,
          thickness: 1,
        ),
        // Liste des rendez-vous à droite
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(
                          "Rendez-vous",
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat.yMMMMd('fr_FR').format(currentSelectedDay),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: appointmentsForSelectedDay.isEmpty
                        ? _buildEmptyState()
                        : _buildAppointmentsList(appointmentsForSelectedDay),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 60),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700], fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Réessayer"),
              onPressed: _loadClientAppointments,
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onError,
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarAndAppointments() {
    final currentSelectedDay = _selectedDay ?? _focusedDay;
    final appointmentsForSelectedDay = _getEventsForDay(currentSelectedDay);

    return Column(
      children: [
        _buildCalendar(),
        const SizedBox(height: 8.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                "Rendez-vous",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                DateFormat.yMMMMd('fr_FR').format(currentSelectedDay),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: appointmentsForSelectedDay.isEmpty
              ? _buildEmptyState()
              : _buildAppointmentsList(appointmentsForSelectedDay),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TableCalendar<Appointment>(
        locale: 'fr_FR',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
          ),
          weekendTextStyle:
              TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle:
              const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left,
              color: Theme.of(context).colorScheme.primary),
          rightChevronIcon: Icon(Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary),
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
    );
  }

  Widget _buildAppointmentsList(List<Appointment> appointments) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _AppointmentCard(
          appointment: appointment,
          onTap: () => _handleAppointmentTap(appointment),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "Aucun rendez-vous ce jour-là.",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = DateFormat.Hm('fr_FR').format(appointment.startTime);
    final endTime = DateFormat.Hm('fr_FR').format(appointment.endTime);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Avec : ${appointment.coiffeurName}",
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, 
                            size: 16, color: theme.colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          "$startTime - $endTime",
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.cancel_outlined, color: Colors.red.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
