import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soifapp/models/haircut_service.dart';
import 'package:soifapp/users_page/coiffeur_details_page.dart';
import 'package:soifapp/users_page/planning_page.dart';
import 'package:soifapp/users_page/salon_location_page.dart';
import 'package:soifapp/users_page/select_service_page.dart';
import 'package:soifapp/users_page/settings_page.dart';
import 'package:soifapp/widgets/logout_button.dart';
import 'package:soifapp/widgets/modern_bottom_nav_bar.dart';
import 'package:timezone/timezone.dart' as tz;

import 'widgets/date_selector.dart';
import 'widgets/service_selector.dart';
import 'widgets/slot_selector.dart';

// Tes fonctions d'aide existantes (inchangées)
IconData _getDynamicIconForCoiffeur(String? id) {
  final icons = [
    Icons.female_rounded,
    Icons.male_rounded,
    Icons.face_retouching_natural_rounded,
    Icons.person_pin_circle_outlined,
    Icons.spa_outlined,
    Icons.content_cut_rounded,
  ];
  if (id == null || id.isEmpty) return Icons.person_outline;
  return icons[id.hashCode % icons.length];
}

Color _getDynamicColorForCoiffeur(String? id) {
  final colors = [
    Colors.pinkAccent[100]!,
    Colors.blueAccent[100]!,
    Colors.purpleAccent[100]!,
    Colors.greenAccent[100]!,
    Colors.orangeAccent[100]!,
    Colors.tealAccent[100]!,
  ];
  if (id == null || id.isEmpty) return Colors.grey[300]!;
  return colors[id.hashCode % colors.length];
}

class Coiffeur {
  final String id;
  final String name;
  final IconData icon; // Conserve l'icône dynamique si tu veux aussi
  final Color color; // Conserve la couleur dynamique si tu veux aussi
  final List<String>? specialites;
  final String? descriptionBio;
  final String? photoUrl; // Nouvelle propriété pour l'URL de la photo

  Coiffeur({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.specialites,
    this.descriptionBio,
    this.photoUrl, // N'oublie pas de l'ajouter ici
  });

  // Nouvelle factory pour Firestore
  factory Coiffeur.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final userId = doc.id;

    return Coiffeur(
      id: userId,
      name: data['nom'] ??
          'Coiffeur inconnu', // 'nom' est directement dans le document utilisateur
      icon: _getDynamicIconForCoiffeur(userId),
      color: _getDynamicColorForCoiffeur(userId),
      specialites: data['specialites'] != null
          ? List<String>.from(data['specialites'])
          : null,
      descriptionBio: data['description_bio'] as String?,
      photoUrl: data['photo_url']
          as String?, // L'URL complète est stockée directement
    );
  }
}

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _selectedDate;
  HaircutService? _selectedService;
  String? _selectedCoiffeurId; // Stockera l'ID du coiffeur sélectionné
  String? _selectedCreneau;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Coiffeur> _coiffeurs = []; // Sera rempli depuis Supabase
  bool _isLoadingCoiffeurs = false;
  String? _coiffeursError;
  List<HaircutService> _allServices = [];
  bool _isLoadingServices = false;
  String? _servicesError;

  // Remplacé par des créneaux dynamiques
  List<String> _dynamicAvailableSlots = [];
  bool _isLoadingSlots = false;
  String? _slotsError;

  // Index pour la barre de navigation inférieure
  int _currentIndex = 0;
  static const int slotIncrementMinutes =
      // ignore: constant_identifier_names
      15; // Granularité pour vérifier les créneaux
  tz.Location? _salonLocation; // Pour stocker la localisation du salon

  @override
  void initState() {
    super.initState();
    _initializeSalonLocation();
    _fetchCoiffeurs();
    _fetchServices();
  }

  Future<void> _initializeSalonLocation() async {
    // Assurez-vous que initializeTimeZones() a été appelé dans main.dart
    try {
      _salonLocation = tz.getLocation(
          'America/Martinique'); // Définissez ici le fuseau horaire de votre salon
    } catch (e) {
      print("Erreur initialisation fuseau horaire salon (BookingPage): $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Erreur de configuration du fuseau horaire. La réservation pourrait être affectée.")),
        );
      }
    }
  }

  Future<void> _fetchCoiffeurs() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCoiffeurs = true;
      _coiffeursError = null;
    });

    try {
      final coiffeursSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coiffeur')
          .where('actif', isEqualTo: true)
          .get();

      final List<Coiffeur> fetchedCoiffeurs = coiffeursSnapshot.docs
          .map((doc) => Coiffeur.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _coiffeurs = fetchedCoiffeurs;
          _isLoadingCoiffeurs = false;
        });
      }
    } catch (e, stacktrace) {
      if (mounted) {
        print('Erreur lors de la récupération des coiffeurs: $e\n$stacktrace');
        setState(() {
          _coiffeursError = 'Impossible de charger les coiffeurs.';
          _isLoadingCoiffeurs = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_coiffeursError!)),
        );
      }
    }
  }

  Future<void> _fetchServices() async {
    if (!mounted) return;
    setState(() {
      _isLoadingServices = true;
      _servicesError = null;
    });

    try {
      final servicesSnapshot =
          await _firestore.collection('haircut_services').get();

      if (mounted) {
        setState(() {
          _allServices = servicesSnapshot.docs
              .map((doc) => HaircutService.fromFirestore(doc))
              .toList();
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Erreur lors de la récupération des services: $e');
        setState(() {
          _servicesError = 'Impossible de charger les services.';
          _isLoadingServices = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_servicesError!)),
        );
      }
    }
  }

  Future<void> _fetchAvailableSlots() async {
    if (_selectedDate == null ||
        _selectedService == null ||
        _selectedCoiffeurId == null) {
      if (mounted) {
        setState(() {
          _dynamicAvailableSlots = [];
          _selectedCreneau = null;
          _isLoadingSlots = false;
          _slotsError = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingSlots = true;
        _slotsError = null;
        _dynamicAvailableSlots = [];
        _selectedCreneau = null;
      });
    }

    try {
      final coiffeurId = _selectedCoiffeurId!;
      final selectedDate = _selectedDate!;
      final serviceDuration = _selectedService!.duration;

      print("--- Début du calcul des créneaux pour le ${selectedDate.toLocal().toString()} ---");
      print("Coiffeur: $coiffeurId, Service: ${_selectedService!.name} (durée: ${serviceDuration.inMinutes} min)");


      final tz.TZDateTime nowInSalon = tz.TZDateTime.now(_salonLocation!);
      final bool isToday = tz.TZDateTime(_salonLocation!, selectedDate.year,
              selectedDate.month, selectedDate.day)
          .isAtSameMomentAs(tz.TZDateTime(_salonLocation!, nowInSalon.year,
              nowInSalon.month, nowInSalon.day));

      final DateTime dayStartUtc = DateTime.utc(
          selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
      final DateTime dayEndUtc = dayStartUtc
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      final selectedDayOfWeek = selectedDate.weekday;
      final workSchedulesSnapshot = await _firestore
 .collection('coiffeur_work_schedules')
          .where('coiffeur_user_id', isEqualTo: coiffeurId)
          .where('day_of_week', isEqualTo: selectedDayOfWeek)
          .orderBy('start_time')
          .get();
      final List<Map<String, dynamic>> workSchedulesData =
          workSchedulesSnapshot.docs.map((d) => d.data()).toList();
      print("Horaires de travail trouvés ($selectedDayOfWeek): $workSchedulesData");

      final appointmentsSnapshot = await _firestore.collection('appointments')
          .where('coiffeur_user_id', isEqualTo: coiffeurId)
          .where('start_time', isLessThan: dayEndUtc)
          .get();
      final List<Map<String, dynamic>> appointmentsData = appointmentsSnapshot.docs
          .where((doc) => (doc.data()['status'] ?? 'confirmed') != 'cancelled_by_client') // Ignorer les RDV annulés
          .map((doc) => doc.data())
          .where((rdv) {
        final rdvEnd = (rdv['end_time'] as Timestamp).toDate();
        return rdvEnd.isAfter(dayStartUtc);
      }).toList();
      print("Rendez-vous existants qui chevauchent la journée: $appointmentsData");


      final absencesSnapshot = await _firestore.collection('coiffeur_absences')
          .where('coiffeur_user_id', isEqualTo: coiffeurId)
          .where('start_time', isLessThan: dayEndUtc)
          .get();
      final List<Map<String, dynamic>> absencesData =
          absencesSnapshot.docs.map((doc) => doc.data()).where((absence) {
        final absenceEnd = (absence['end_time'] as Timestamp).toDate();
        return absenceEnd.isAfter(dayStartUtc);
      }).toList();
      print("Absences qui chevauchent la journée: $absencesData");

      final List<String> calculatedSlots = [];
      final DateFormat timeFormatter = DateFormat.Hm('fr_FR');

      for (var schedule in workSchedulesData) {
        final String startTimeStr = schedule['start_time'] as String;
        final String endTimeStr = schedule['end_time'] as String;

        final startParts = startTimeStr.split(':');
        final endParts = endTimeStr.split(':');

        final tz.TZDateTime availabilityStart = tz.TZDateTime(
            _salonLocation!,
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            int.parse(startParts[0]),
            int.parse(startParts[1]));
        final tz.TZDateTime availabilityEnd = tz.TZDateTime(
            _salonLocation!,
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            int.parse(endParts[0]),
            int.parse(endParts[1]));

        tz.TZDateTime potentialSlotStart = availabilityStart;

        while (
            potentialSlotStart.add(serviceDuration).isBefore(availabilityEnd) ||
                potentialSlotStart
                    .add(serviceDuration)
                    .isAtSameMomentAs(availabilityEnd)) {
          final tz.TZDateTime potentialSlotEnd =
              potentialSlotStart.add(serviceDuration);

          if (isToday && potentialSlotStart.isBefore(nowInSalon)) {
            potentialSlotStart = potentialSlotStart
                .add(const Duration(minutes: slotIncrementMinutes));
            continue;
          }

          final bool isBooked = appointmentsData.any((appointment) {
            final rdvStart = tz.TZDateTime.from(
                (appointment['start_time'] as Timestamp).toDate(),
                _salonLocation!);
            final rdvEnd = tz.TZDateTime.from(
                (appointment['end_time'] as Timestamp).toDate(),
                _salonLocation!);
            return potentialSlotStart.isBefore(rdvEnd) &&
                potentialSlotEnd.isAfter(rdvStart);
          });

          final bool isAbsent = absencesData.any((absence) {
            final absenceStart = tz.TZDateTime.from(
                (absence['start_time'] as Timestamp).toDate(),
                _salonLocation!);
            final absenceEnd = tz.TZDateTime.from(
                (absence['end_time'] as Timestamp).toDate(), _salonLocation!);
            return potentialSlotStart.isBefore(absenceEnd) &&
                potentialSlotEnd.isAfter(absenceStart);
          });

          if (!isBooked && !isAbsent) {
            calculatedSlots.add(timeFormatter.format(potentialSlotStart));
          } else {
            print(
                'Créneau ${timeFormatter.format(potentialSlotStart)} rejeté. RDV: $isBooked, Absence: $isAbsent');
          }

          potentialSlotStart = potentialSlotStart
              .add(const Duration(minutes: slotIncrementMinutes));
        }
      }

      if (mounted) {
        setState(() {
          _dynamicAvailableSlots = calculatedSlots.toSet().toList()..sort();
          _isLoadingSlots = false;
          print("Créneaux finaux trouvés: $_dynamicAvailableSlots");
        });
      }
    } catch (e, stacktrace) {
      print('Erreur lors de la récupération des créneaux: $e');
      print(stacktrace);
      if (mounted) {
        setState(() {
          _slotsError = 'Impossible de charger les créneaux disponibles.';
          _isLoadingSlots = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_slotsError!)),
        );
      }
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now()
          .add(const Duration(days: 60)), // Réservable sur 60 jours
      locale: const Locale('fr', 'FR'), // Ajout de la locale française ici
      builder: (context, child) {
        // Le DatePicker utilisera désormais le thème global de l'application
        // ou vous pouvez définir un thème spécifique ici qui s'adapte
        return Theme(
          data: Theme.of(context), // Utilise le thème parent
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        // Si la date change, on pourrait vouloir réinitialiser le service, coiffeur et créneau
        // _selectedService = null; // Optionnel, selon le flux désiré
        _selectedCreneau = null; // Réinitialiser le créneau si la date change
      });
    }
    _fetchAvailableSlots(); // Mettre à jour les créneaux si la date change
  }

  void _navigateToSelectServicePage() async {
    final HaircutService? selectedService =
        await Navigator.push<HaircutService>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectServicePage(allServices: _allServices),
      ),
    );

    if (selectedService != null) {
      setState(() {
        _selectedService = selectedService;
        _selectedCoiffeurId =
            null; // Réinitialiser le coiffeur si le service change
        _selectedCreneau =
            null; // Réinitialiser le créneau si le service change
      });
      _fetchAvailableSlots(); // Mettre à jour les créneaux si le service change
    }
  }

  Widget _buildCoiffeurSelector() {
    if (_isLoadingCoiffeurs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_coiffeursError != null) {
      return Center(
          child: Text(_coiffeursError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)));
    }

    if (_coiffeurs.isEmpty) {
      return const Center(
          child: Text('Aucun coiffeur disponible pour le moment.'));
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _coiffeurs.length,
        itemBuilder: (context, index) {
          final coiffeur = _coiffeurs[index];
          final isSelected = _selectedCoiffeurId == coiffeur.id;
          return GestureDetector(
            onTap: () async {
              final selectedId = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => CoiffeurDetailsPage(coiffeur: coiffeur),
                ),
              );

              // Si un coiffeur a été choisi depuis la page de détails
              if (selectedId != null && mounted) {
                setState(() {
                  _selectedCoiffeurId = selectedId;
                  _selectedCreneau = null;
                });
                _fetchAvailableSlots(); // Mettre à jour les créneaux
              }
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.5)
                          : Border.all(color: Colors.transparent, width: 2.5),
                    ),
                    child: coiffeur.photoUrl != null &&
                            coiffeur.photoUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: 35,
                            backgroundImage:
                                CachedNetworkImageProvider(coiffeur.photoUrl!),
                            backgroundColor:
                                Colors.grey[200], // Placeholder couleur
                          )
                        : CircleAvatar(
                            radius: 35,
                            backgroundColor: coiffeur.color.withOpacity(0.8),
                            child: Icon(coiffeur.icon,
                                size: 30, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coiffeur.name,
                    style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex && index == 0) {
      return; // Déjà sur RDV et on clique sur RDV
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PlanningPage()),
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
      // index == 0 (RDV)
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservation'),
        // Les couleurs de l'AppBar sont maintenant gérées par AppBarTheme dans main.dart
        actions: [
          const LogoutButton(), // Utilisation du widget refactorisé
        ],
        // Si vous voulez un bouton de retour standard qui n'est pas lié à la déconnexion,
        // Flutter l'ajoute automatiquement si BookingPage n'est pas la première route.
        // Pour un contrôle explicite, vous pouvez utiliser `leading: BackButton(),`
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
            15.0), // Ajout de padding pour éviter que le contenu ne touche les bords
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Sélecteur de date
            DateSelector(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                  _selectedCreneau = null;
                });
                _fetchAvailableSlots();
              },
              onPickDateTap: _pickDate,
            ),
            const SizedBox(height: 30),

            // Choix du service
            if (_isLoadingServices)
              const Center(child: CircularProgressIndicator())
            else if (_servicesError != null)
              Center(
                  child: Text(_servicesError!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)))
            else if (_allServices.isEmpty)
              _buildInfoMessage('Aucun service disponible pour le moment.')
            else ...[
              ServiceSelector(
                selectedService: _selectedService,
                onTap: _navigateToSelectServicePage,
              ),
            ],
            const SizedBox(height: 30),

            // Choix du coiffeur
            if (_selectedDate != null && _selectedService != null) ...[
              Text('3. Choisissez votre coiffeur/coiffeuse :',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 15),
              _buildCoiffeurSelector(),
              const SizedBox(height: 30)
            ] else if (_selectedDate != null && _selectedService == null)
              _buildInfoMessage('Veuillez d\'abord choisir un service.'),

            // Affichage des créneaux (seulement si date et coiffeur sont choisis)
            if (_selectedDate != null &&
                _selectedService != null &&
                _selectedCoiffeurId != null) ...[
              Text(
                  '4. Choisissez un créneau pour ${_selectedService!.name} avec ${_coiffeurs.firstWhere((c) => c.id == _selectedCoiffeurId).name} le ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} :',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 10),
              Center(
                child: SlotSelector(
                  availableSlots: _dynamicAvailableSlots,
                  selectedSlot: _selectedCreneau,
                  onSlotSelected: (slot) {
                    setState(() {
                      _selectedCreneau = slot;
                    });
                  },
                  selectedService: _selectedService,
                  isLoading: _isLoadingSlots,
                  error: _slotsError,
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.check_circle_outline, /*color: Colors.white*/
                  ), // La couleur de l'icône sera gérée par le thème du bouton
                  label: const Text(
                    'Confirmer la réservation', /*style: TextStyle(color: Colors.white)*/
                  ), // La couleur du texte aussi
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCreneau != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                  ),
                  // ...
                  onPressed: _selectedCreneau != null
                      ? _confirmBooking // Appel de la méthode de confirmation
                      : null,
                  // ...
                  // Bouton désactivé si aucun créneau n'est choisi
                ),
              ),
            ] else if (_selectedDate != null &&
                _selectedService != null &&
                _selectedCoiffeurId == null)
              _buildInfoMessage(
                  'Veuillez choisir un coiffeur pour voir les créneaux.'),

            // Message initial si rien n'est encore sélectionné (ou seulement la date)
            if (_selectedDate == null)
              _buildInfoMessage('Veuillez d\'abord sélectionner une date.'),
          ],
        ),
      ),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildInfoMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              fontStyle: FontStyle.italic,
              fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _confirmBooking() async {
    if (_selectedDate == null ||
        _selectedService == null ||
        _selectedCoiffeurId == null ||
        _selectedCreneau == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez compléter toutes les sélections.')),
      );
      return;
    }

    if (_salonLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Erreur de configuration du fuseau horaire. Réservation annulée.')),
      );
      setState(() {
        // Optionnel: Arrêter l'indicateur de chargement si vous en utilisez un ici
      });
      return;
    }
    setState(() {
      // Optionnel: Mettre un indicateur de chargement sur le bouton ou globalement
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("Utilisateur non connecté.");
      }

      final timeParts = _selectedCreneau!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Créer un TZDateTime dans le fuseau horaire du salon
      final salonStartTime = tz.TZDateTime(
        _salonLocation!,
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hour,
        minute,
      );

      // Convertir en UTC pour le stockage
      final utcStartTime = salonStartTime.toUtc();
      final utcEndTime = salonStartTime.add(_selectedService!.duration).toUtc();

      // Récupérer le nom du client et du coiffeur
      final clientDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final clientName = clientDoc.data()?['nom'] as String? ?? 'Client inconnu';

      // Récupérer le nom du coiffeur sélectionné
      final coiffeurName = _coiffeurs
          .firstWhere((c) => c.id == _selectedCoiffeurId,
              orElse: () => Coiffeur(id: '', name: 'Inconnu', icon: Icons.error, color: Colors.red))
          .name;

      await _firestore.collection('appointments').add({
        'client_user_id': currentUser.uid,
        'client_name': clientName, // Ajout du nom du client
        'coiffeur_user_id': _selectedCoiffeurId,
        'coiffeur_name': coiffeurName, // Ajout du nom du coiffeur
        'service_id': _selectedService!.id,
        'start_time': Timestamp.fromDate(utcStartTime),
        'end_time': Timestamp.fromDate(utcEndTime),
        'duration_minutes': _selectedService!.duration.inMinutes,
        'service_name': _selectedService!.name,
        'price_at_booking': _selectedService!.price,
        'status': 'confirmed',
        'notes': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rendez-vous confirmé avec succès !'),
            backgroundColor: Colors.green[600],
          ),
        );
        // Naviguer vers la page de gestion des RDV ou le planning
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const PlanningPage()), // Ou ManageAppointmentsPage
        );
      }
    } catch (e) {
      if (mounted) {
        print("Erreur lors de la confirmation du RDV: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de la confirmation: ${e.toString()}')),
        );
      }
    } finally {
      // Optionnel: Arrêter l'indicateur de chargement
    }
  }
}
