import 'package:flutter/material.dart';
import 'package:soifapp/booking_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Pour le formatage des dates
import 'package:soifapp/salon_location_page.dart'; // Importer la page Localisation
import 'package:soifapp/widgets/modern_bottom_nav_bar.dart'; // Importer le widget refactorisé
import 'package:soifapp/settings_page.dart'; // Importer la page Paramètres

// Classe simple pour représenter un rendez-vous
class Appointment {
  final String title;
  final String serviceName;
  final String coiffeurName;
  final DateTime startTime;
  final Duration duration;

  Appointment({
    required this.title,
    required this.serviceName,
    required this.coiffeurName,
    required this.startTime,
    required this.duration,
  });

  DateTime get endTime => startTime.add(duration);
}

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Appointment>> _events = {};

  // Index pour la barre de navigation inférieure, initialisé à 1 pour "Planning"
  int _currentIndex = 1;

  // Données de rendez-vous fictives pour l'exemple
  // Dans une vraie application, ces données viendraient d'une base de données ou d'un état global
  final List<Appointment> _sampleAppointments = [
    Appointment(
      title: 'RDV Sophie - Coupe Femme',
      serviceName: 'Coupe & Brushing Femme',
      coiffeurName: 'Sophie',
      startTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
      duration: const Duration(minutes: 60),
    ),
    Appointment(
      title: 'RDV Julien - Dégradé',
      serviceName: 'Dégradé Américain',
      coiffeurName: 'Julien',
      startTime: DateTime.now().add(const Duration(days: 2, hours: 14)),
      duration: const Duration(minutes: 45),
    ),
    Appointment(
      title: 'RDV Chloé - Couleur',
      serviceName: 'Couleur Femme (racines)',
      coiffeurName: 'Chloé',
      startTime:
          DateTime.now().add(const Duration(days: 5, hours: 9, minutes: 30)),
      duration: const Duration(hours: 1, minutes: 30),
    ),
    Appointment(
      title: 'RDV Sophie - Brushing',
      serviceName: 'Brushing Simple',
      coiffeurName: 'Sophie',
      startTime: DateTime.now().add(const Duration(days: 5, hours: 15)),
      duration: const Duration(minutes: 30),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _currentIndex = 1; // S'assurer que l'onglet Planning est sélectionné
    _groupAppointments();
  }

  void _groupAppointments() {
    _events = {};
    for (var appointment in _sampleAppointments) {
      // Normaliser la date pour qu'elle corresponde à la clé du Map (sans l'heure)
      DateTime dateKey = DateTime(appointment.startTime.year,
          appointment.startTime.month, appointment.startTime.day);
      if (_events[dateKey] == null) {
        _events[dateKey] = [];
      }
      _events[dateKey]!.add(appointment);
    }
  }

  List<Appointment> _getEventsForDay(DateTime day) {
    DateTime dateKey = DateTime(day.year, day.month, day.day);
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

  void _onNavBarTap(int index) {
    if (index == _currentIndex && index == 1)
      return; // Déjà sur Planning et on clique sur Planning

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BookingPage()),
      );
    } else if (index == 2) {
      // Nouvel onglet Localisation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SalonLocationPage()),
      );
    } else if (index == 3) {
      // Paramètres est maintenant à l'index 3
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    } else {
      // index == 1 (Planning)
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsForSelectedDay = _getEventsForDay(_selectedDay!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Planning'),
        // Les couleurs de l'AppBar sont maintenant gérées par AppBarTheme dans main.dart
      ),
      body: Column(
        children: [
          TableCalendar<Appointment>(
            locale: 'fr_FR', // Pour le format français
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              // Utilisation des couleurs du thème
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              defaultTextStyle:
                  TextStyle(color: Theme.of(context).colorScheme.onSurface),
              weekendTextStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .primary), // Exemple pour les weekends
              todayTextStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer), // Pour le jour actuel
              selectedTextStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary), // Pour le jour sélectionné
            ),
            headerStyle: HeaderStyle(
              formatButtonTextStyle:
                  TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              formatButtonDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16.0),
              ),
              titleTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left,
                  color: Theme.of(context).colorScheme.primary),
              rightChevronIcon: Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.bold),
              weekendStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
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
          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Rendez-vous pour le ${DateFormat.yMMMMd('fr_FR').format(_selectedDay!)} :",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary),
            ),
          ),
          Expanded(
            child: appointmentsForSelectedDay.isEmpty
                ? Center(
                    child: Text(
                      "Aucun rendez-vous prévu pour ce jour.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ), // Peut aussi utiliser Theme.of(context).textTheme.bodyMedium
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: appointmentsForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final appointment = appointmentsForSelectedDay[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10)), // La couleur de la carte s'adaptera au thème
                        // color: Theme.of(context).cardColor, // Explicitement, ou laisser le thème gérer
                        child: ListTile(
                          leading: Icon(Icons.event_available,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(
                            appointment.serviceName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                          subtitle: Text(
                            "${DateFormat.Hm('fr_FR').format(appointment.startTime)} - ${DateFormat.Hm('fr_FR').format(appointment.endTime)}\nAvec : ${appointment.coiffeurName}",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7)),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
