import 'package:flutter/material.dart';
import 'package:soifapp/users_page/booking_page.dart';
import 'package:soifapp/widgets/logout_button.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Pour le formatage des dates
import 'package:soifapp/users_page/salon_location_page.dart'; // Importer la page Localisation
import 'package:supabase_flutter/supabase_flutter.dart'; // Importer Supabase
import 'package:timezone/timezone.dart' as tz; // Importer le package timezone

import 'package:soifapp/widgets/modern_bottom_nav_bar.dart'; // Importer le widget refactorisé
import 'package:soifapp/users_page/settings_page.dart'; // Importer la page Paramètres

// Classe simple pour représenter un rendez-vous
class Appointment {
  final String title;
  final String serviceName;
  final String coiffeurName;
  final tz.TZDateTime startTime; // Utiliser TZDateTime
  final Duration duration;

  Appointment({
    required this.title,
    required this.serviceName,
    required this.coiffeurName,
    required this.startTime,
    required this.duration,
  });

  tz.TZDateTime get endTime => tz.TZDateTime.fromMillisecondsSinceEpoch(
      startTime.location,
      startTime.millisecondsSinceEpoch + duration.inMilliseconds);
}

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks; // Modifié ici
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Appointment>> _events = {};
  bool _isLoading = true;
  String? _errorMessage;
  tz.Location? _salonLocation; // Pour stocker la localisation du salon

  // Index pour la barre de navigation inférieure, initialisé à 1 pour "Planning"
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _currentIndex = 1; // S'assurer que l'onglet Planning est sélectionné
    _initializeSalonLocationAndLoadAppointments();
  }

  Future<void> _initializeSalonLocationAndLoadAppointments() async {
    // Assurez-vous que initializeTimeZones() a été appelé dans main.dart
    // Définissez ici le fuseau horaire de votre salon
    try {
      _salonLocation = tz.getLocation('Europe/Paris');
      await _loadClientAppointments();
    } catch (e) {
      print("Erreur lors de l'initialisation du fuseau horaire du salon: $e");
      // Gérer l'erreur, peut-être afficher un message à l'utilisateur
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
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception("Utilisateur non connecté pour charger le planning.");
      }

      final response = await Supabase.instance.client
          .from('appointments')
          .select(
              '*, coiffeur_profile:profiles!appointments_coiffeur_user_id_fkey(nom)')
          .eq('client_user_id', currentUser.id)
          .order('start_time', ascending: true);

      if (!mounted) return;

      final List<Appointment> loadedAppointments = [];
      for (var item in response) {
        final coiffeurName = (item['coiffeur_profile'] != null &&
                (item['coiffeur_profile'] as Map).containsKey('nom'))
            ? item['coiffeur_profile']['nom'] as String? ?? 'Coiffeur inconnu'
            : 'Coiffeur inconnu';
        final serviceName =
            item['service_name'] as String? ?? 'Service inconnu';

        loadedAppointments.add(
          Appointment(
            title: 'RDV $coiffeurName - $serviceName', // Titre construit
            serviceName: serviceName,
            coiffeurName: coiffeurName,
            // Convertir l'heure UTC de la DB en TZDateTime dans le fuseau du salon
            startTime: tz.TZDateTime.from(
                DateTime.parse(
                    item['start_time'] as String), // Ceci est une heure UTC
                _salonLocation!),
            duration: Duration(minutes: item['duration_minutes'] as int),
          ),
        );
      }
      _groupAppointments(loadedAppointments); // Passer les RDV chargés
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print("Erreur chargement RDV client: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Erreur de chargement des rendez-vous: ${e.toString()}";
      });
    }
  }

  void _groupAppointments([List<Appointment> appointments = const []]) {
    _events = {};
    for (var appointment in appointments) {
      // Normaliser la date pour qu'elle corresponde à la clé du Map (sans l'heure)
      // Utiliser les composants de TZDateTime pour créer la clé
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
    // 'day' vient du TableCalendar, qui utilise DateTime local.
    // Convertir en TZDateTime pour la clé si 'day' est un jour sélectionné.
    // Pour la clé du map _events, nous utilisons déjà des TZDateTime normalisés à minuit.
    DateTime dateKey =
        tz.TZDateTime(_salonLocation!, day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        // Si vous voulez que _focusedDay soit aussi un TZDateTime pour la cohérence interne:
        // if (_salonLocation != null) {
        //   _focusedDay = tz.TZDateTime(_salonLocation!, focusedDay.year, focusedDay.month, focusedDay.day);
        // }
      });
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex && index == 1) {
      return; // Déjà sur Planning et on clique sur Planning
    }

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
    // S'assurer que _selectedDay n'est jamais null après initState
    final currentSelectedDay = _selectedDay ?? _focusedDay;
    final appointmentsForSelectedDay = _getEventsForDay(currentSelectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Planning'),
        // Ajout d'un bouton de rafraîchissement
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadClientAppointments,
          tooltip: 'Rafraîchir le planning',
        ),
        actions: [
          const LogoutButton(), // Ajout du bouton de déconnexion
        ],
        // Les couleurs de l'AppBar sont maintenant gérées par AppBarTheme dans main.dart
      ),
      body: Column(
        children: [
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else ...[
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                    fontWeight: FontWeight.bold),
                weekendStyle: TextStyle(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
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
                "Rendez-vous pour le ${DateFormat.yMMMMd('fr_FR').format(currentSelectedDay)} :",
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
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
          ]
        ],
      ),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
