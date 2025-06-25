import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soifapp/models/haircut_service.dart';
import 'package:soifapp/users_page/coiffeur_details_page.dart';
import 'package:soifapp/users_page/planning_page.dart';
import 'package:soifapp/users_page/salon_location_page.dart';
import 'package:soifapp/users_page/select_service_page.dart';
import 'package:soifapp/users_page/settings_page.dart';
import 'package:soifapp/widgets/logout_button.dart';
import 'package:soifapp/widgets/modern_bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  factory Coiffeur.fromSupabase({
    required Map<String, dynamic> coiffeurData,
    required String profileName,
    required SupabaseClient supabaseClient,
  }) {
    String userId = coiffeurData['user_id'] as String;
    String? photoPath = coiffeurData['photo_url'] as String?;
    String? trimmedPhotoPath =
        photoPath?.trim(); // Nettoyer les espaces et sauts de ligne

    String? publicPhotoUrl;
    if (trimmedPhotoPath != null && trimmedPhotoPath.isNotEmpty) {
      try {
        publicPhotoUrl = supabaseClient.storage
            .from('photos.coiffeurs')
            .getPublicUrl(trimmedPhotoPath); // Utiliser le chemin nettoyé
      } catch (e) {
        print(
            'Erreur lors de la récupération de l\'URL publique pour $trimmedPhotoPath: $e');
        publicPhotoUrl = null;
      }
    }
    // ... rest of your factory

    return Coiffeur(
      id: userId,
      name: profileName,
      icon: _getDynamicIconForCoiffeur(userId),
      color: _getDynamicColorForCoiffeur(userId),
      specialites: coiffeurData['specialites'] != null
          ? List<String>.from(coiffeurData['specialites'])
          : null,
      descriptionBio: coiffeurData['description_bio'] as String?,
      photoUrl: publicPhotoUrl, // Assigne l'URL publique ici
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

  final SupabaseClient _supabaseClient = Supabase.instance.client;
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
      final List<Map<String, dynamic>> activeCoiffeursData =
          await _supabaseClient
              .from('coiffeurs')
              .select(
                  'user_id, specialites, description_bio, photo_url') // <-- AJOUTE 'photo_url' ICI
              .eq('actif', true);

      if (activeCoiffeursData.isEmpty) {
        if (mounted) {
          setState(() {
            _coiffeurs = [];
            _isLoadingCoiffeurs = false;
          });
        }
        return;
      }

      final List<String> userIds =
          activeCoiffeursData.map((c) => c['user_id'] as String).toList();

      if (userIds.isEmpty) {
        if (mounted) {
          setState(() {
            _coiffeurs = [];
            _isLoadingCoiffeurs = false;
          });
        }
        return;
      }

      final List<Map<String, dynamic>> profilesData = await _supabaseClient
          .from('profiles')
          .select('id, nom')
          .filter('id', 'in', userIds);

      final List<Coiffeur> fetchedCoiffeurs = [];
      for (var coiffeurRecord in activeCoiffeursData) {
        final profileRecord = profilesData.firstWhere(
          (p) => p['id'] == coiffeurRecord['user_id'],
          orElse: () => <String, dynamic>{},
        );

        if (profileRecord.isNotEmpty && profileRecord['nom'] != null) {
          fetchedCoiffeurs.add(Coiffeur.fromSupabase(
            coiffeurData: coiffeurRecord,
            profileName: profileRecord['nom'] as String,
            supabaseClient: _supabaseClient, // <-- PASSE LE CLIENT SUPABASE ICI
          ));
        } else {
          print(
              'Avertissement: Coiffeur ID ${coiffeurRecord['user_id']} actif mais profil ou nom manquant.');
        }
      }

      if (mounted) {
        setState(() {
          _coiffeurs = fetchedCoiffeurs;
          _isLoadingCoiffeurs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Erreur lors de la récupération des coiffeurs: $e');
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
      final List<Map<String, dynamic>> servicesData =
          await _supabaseClient.from('haircut_services').select();

      if (mounted) {
        setState(() {
          _allServices = servicesData
              .map((data) => HaircutService.fromSupabase(data))
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
      final workSchedulesResponse = await _supabaseClient
          .from('coiffeur_work_schedules')
          .select('start_time, end_time')
          .eq('coiffeur_user_id', coiffeurId)
          .eq('day_of_week', selectedDayOfWeek)
          .order('start_time', ascending: true);
      final List<Map<String, dynamic>> workSchedulesData =
          List<Map<String, dynamic>>.from(workSchedulesResponse);

      final appointmentsResponse = await _supabaseClient
          .from('appointments')
          .select('start_time, end_time')
          .eq('coiffeur_user_id', coiffeurId)
          .lt('start_time', dayEndUtc.toIso8601String())
          .gt('end_time', dayStartUtc.toIso8601String());
      final List<Map<String, dynamic>> appointmentsData =
          List<Map<String, dynamic>>.from(appointmentsResponse);

      final absencesResponse = await _supabaseClient
          .from('coiffeur_absences')
          .select('start_time, end_time')
          .eq('coiffeur_user_id', coiffeurId)
          .lt('start_time', dayEndUtc.toIso8601String())
          .gt('end_time', dayStartUtc.toIso8601String());
      final List<Map<String, dynamic>> absencesData =
          List<Map<String, dynamic>>.from(absencesResponse);

      print(
          "Absences pour ${coiffeurId} le ${selectedDate.toLocal()}: $absencesData");

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
                DateTime.parse(appointment['start_time'] as String),
                _salonLocation!);
            final rdvEnd = tz.TZDateTime.from(
                DateTime.parse(appointment['end_time'] as String),
                _salonLocation!);
            return potentialSlotStart.isBefore(rdvEnd) &&
                potentialSlotEnd.isAfter(rdvStart);
          });

          final bool isAbsent = absencesData.any((absence) {
            final absenceStart = tz.TZDateTime.from(
                DateTime.parse(absence['start_time'] as String),
                _salonLocation!);
            final absenceEnd = tz.TZDateTime.from(
                DateTime.parse(absence['end_time'] as String), _salonLocation!);
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
                            backgroundImage: NetworkImage(coiffeur.photoUrl!),
                            backgroundColor:
                                Colors.grey[200], // Placeholder couleur
                            onBackgroundImageError: (exception, stackTrace) {
                              // Gérer les erreurs de chargement d'image
                              print(
                                  'Erreur de chargement d\'image pour ${coiffeur.name}: $exception');
                            },
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
        padding: const EdgeInsets.all(20.0),
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
              SlotSelector(
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
      final currentUser = _supabaseClient.auth.currentUser;
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

      await _supabaseClient.from('appointments').insert({
        'client_user_id': currentUser.id,
        'coiffeur_user_id': _selectedCoiffeurId,
        'service_id': _selectedService!.id,
        'start_time':
            utcStartTime.toIso8601String(), // Envoie une chaîne UTC (ex: ...Z)
        'end_time':
            utcEndTime.toIso8601String(), // Envoie une chaîne UTC (ex: ...Z)
        'duration_minutes': _selectedService!.duration.inMinutes,
        'service_name': _selectedService!.name,
        'price_at_booking': _selectedService!.price,
        'status': 'confirmed', // Statut initial
        // 'notes': null, // Ajoutez un champ pour les notes si nécessaire
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
