import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soifapp/models/haircut_service.dart';
import 'package:soifapp/models/sub_category.dart';
import 'package:soifapp/users_page/coiffeur_details_page.dart';
import 'package:soifapp/users_page/planning_page.dart';
import 'package:soifapp/users_page/salon_location_page.dart';
import 'package:soifapp/users_page/select_service_page.dart';
import 'package:soifapp/users_page/settings_page.dart';
import 'package:soifapp/widgets/logout_button.dart';
import 'package:soifapp/widgets/modern_bottom_nav_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:timezone/timezone.dart' as tz;

import 'widgets/date_selector.dart';
import 'widgets/service_selector.dart';
import 'widgets/slot_selector.dart';

// Tes fonctions d aide existantes (inchangées)
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
  final IconData icon; // Conserve l icon dynamique si tu veux aussi
  final Color color; // Conserve la couleur dynamique si tu veux aussi
  final List<String>? specialites;
  final String? descriptionBio;
  final String? photoUrl; // Nouvelle propriete pour l URL de la photo

  Coiffeur({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.specialites,
    this.descriptionBio,
    this.photoUrl, // N oublie pas de l ajouter ici
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
          as String?, // L URL complete est stockee directement
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
  String? _selectedCoiffeurId; // Stockera l ID du coiffeur sélectionné
  String? _selectedCreneau;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Coiffeur> _coiffeurs = []; // Sera rempli depuis Supabase
  bool _isLoadingCoiffeurs = true;
  String? _coiffeursError;
  List<HaircutService> _allServices = [];
  bool _isLoadingServices = true;
  String? _servicesError;
  List<SubCategory> _allSubCategories = [];
  bool _isLoadingSubCategories = true;
  // ignore: unused_field
  String? _subCategoriesError;
  bool _imagesPrecached = false;


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
    _fetchAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache images after the first frame is built and data is fetched.
    if (!_imagesPrecached && !_isLoadingCoiffeurs && !_isLoadingSubCategories && !_isLoadingServices) {
      _precacheAllImages();
      _imagesPrecached = true;
    }
  }

  void _precacheAllImages() {
    if (!mounted) return;
    // Pre-cache coiffeur images
    for (final coiffeur in _coiffeurs) {
      if (coiffeur.photoUrl != null && coiffeur.photoUrl!.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(coiffeur.photoUrl!), context);
      }
    }
    // Pre-cache sub-category images
    for (final subCategory in _allSubCategories) {
      if (subCategory.imageUrl != null && subCategory.imageUrl!.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(subCategory.imageUrl!), context);
      }
    }
    // Pre-cache service images
    for (final service in _allServices) {
      if (service.imagePlaceholder.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(service.imagePlaceholder), context);
      }
    }
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchCoiffeurs(),
      _fetchServices(),
      _fetchSubCategories(),
    ]);
    // Trigger pre-caching after all data is fetched and state is updated.
    if (mounted && !_imagesPrecached) {
      // A short delay to ensure the context is ready for precaching.
      Future.delayed(const Duration(milliseconds: 500), () {
        _precacheAllImages();
        _imagesPrecached = true;
      });
    }
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_coiffeursError!)));
      }
    }
  }

  Future<List<HaircutService>> _fetchServices() async {
    if (!mounted) return [];
    setState(() {
      _isLoadingServices = true;
      _servicesError = null;
    });

    try {
      final servicesSnapshot =
          await _firestore.collection('haircut_services').get();

      final fetchedServices = servicesSnapshot.docs
          .map((doc) => HaircutService.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _allServices = fetchedServices;
          _isLoadingServices = false;
        });
      }
      return fetchedServices;
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
      return []; // Retourne une liste vide en cas d erreur
    }
  }

  Future<void> _fetchSubCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSubCategories = true;
      _subCategoriesError = null;
    });

    try {
      final snapshot =
          await _firestore.collection('sub_categories').get();
      if (mounted) {
        setState(() {
          _allSubCategories =
              snapshot.docs.map((doc) => SubCategory.fromFirestore(doc)).toList();
          _isLoadingSubCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Erreur fetchSubCategories: $e');
        setState(() {
          _subCategoriesError = "Impossible de charger les catégories.";
          _isLoadingSubCategories = false;
        });
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
      final workSchedulesSnapshot = await _firestore
 .collection('coiffeur_work_schedules')
          .where('coiffeur_user_id', isEqualTo: coiffeurId)
          .where('day_of_week', isEqualTo: selectedDayOfWeek)
          .orderBy('start_time')
          .get();
      final List<Map<String, dynamic>> workSchedulesData =
          workSchedulesSnapshot.docs.map((d) => d.data()).toList();

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


      final absencesSnapshot = await _firestore.collection('coiffeur_absences')
          .where('coiffeur_user_id', isEqualTo: coiffeurId)
          .where('start_time', isLessThan: dayEndUtc)
          .get();
      final List<Map<String, dynamic>> absencesData =
          absencesSnapshot.docs.map((doc) => doc.data()).where((absence) {
        final absenceEnd = (absence['end_time'] as Timestamp).toDate();
        return absenceEnd.isAfter(dayStartUtc);
      }).toList();

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
            potentialSlotStart =
                potentialSlotStart.add(const Duration(minutes: slotIncrementMinutes));
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
            final absenceEnd = tz.TZDateTime.from((absence['end_time'] as Timestamp).toDate(), _salonLocation!);
            return potentialSlotStart.isBefore(absenceEnd) &&
                potentialSlotEnd.isAfter(absenceStart);
          });

          if (!isBooked && !isAbsent) {
            calculatedSlots.add(timeFormatter.format(potentialSlotStart));
          }

          potentialSlotStart =
              potentialSlotStart.add(const Duration(minutes: slotIncrementMinutes));
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
        // Le DatePicker utilisera désormais le thème global de l application
        // ou vous pouvez définir un thème spécifique ici qui s adapte
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
        builder: (context) => SelectServicePage(
          allServices: _allServices,
          allSubCategories: _allSubCategories,
          onRefresh: _fetchServices,
        ),
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
      return Center(
        child: SpinKitFadingCircle(
          color: Theme.of(context).colorScheme.primary,
          size: 50.0,
        ),
      );
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
                  Hero(
                    tag: 'coiffeur-photo-${coiffeur.id}',
                    child: Container(
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
                          ? CachedNetworkImage(
                              imageUrl: coiffeur.photoUrl!,
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                radius: 35,
                                backgroundImage: imageProvider,
                              ),
                              placeholder: (context, url) => const CircleAvatar(
                                radius: 35, // Maintenir la taille
                                backgroundColor: Colors.grey, // Couleur de fond
                                child: SpinKitFadingCircle(
                                  color: Colors.white,
                                  size: 30.0,
                                ),
                              ),
                              errorWidget: (context, url, error) => CircleAvatar(
                                radius: 35,
                                backgroundColor: coiffeur.color.withOpacity(0.8),
                                child: Icon(coiffeur.icon,
                                    size: 30, color: Colors.white),
                              ),
                            )
                          : CircleAvatar(
                              radius: 35,
                              backgroundColor: coiffeur.color.withOpacity(0.8),
                              child: Icon(coiffeur.icon,
                                  size: 30, color: Colors.white),
                            ),
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
          )
              .animate()
              .fadeIn(delay: (100 * index).ms, duration: 400.ms)
              .slideX(begin: 0.5, curve: Curves.easeOutCubic)
              .shimmer(delay: (100 * index).ms, duration: 600.ms);
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
      // Paramètres est maintenant à l index 3
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isLoading = _isLoadingServices || _isLoadingSubCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Réservation'),
        actions: const [
          LogoutButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionCard(
              context: context,
              step: '1',
              title: 'Choisissez une date',
              content: DateSelector(
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
            ),
            _buildSectionCard(
              context: context,
              step: '2',
              title: 'Choisissez une prestation',
              content: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _servicesError != null
                      ? Center(
                          child: Text(_servicesError!,
                              style: TextStyle(color: colorScheme.error)))
                      : ServiceSelector(
                          selectedService: _selectedService,
                          onTap: _navigateToSelectServicePage,
                        ),
            ),
            if (_selectedDate != null && _selectedService != null)
              _buildSectionCard(
                context: context,
                step: '3',
                title: 'Choisissez un coiffeur',
                content: _buildCoiffeurSelector(),
              ).animate().fadeIn(duration: 400.ms),
            if (_selectedDate != null &&
                _selectedService != null &&
                _selectedCoiffeurId != null)
              _buildSectionCard(
                context: context,
                step: '4',
                title: 'Choisissez un créneau',
                content: Center(
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
              ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 80), // Espace pour le bouton
          ],
        ),
      ),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
      floatingActionButton: _selectedCreneau != null
          ? FloatingActionButton.extended(
              onPressed: _confirmBooking,
              label: const Text('Confirmer la réservation'),
              icon: const Icon(Icons.check_circle_outline),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary, // Fix: Use scale instead of scaleIn
            ).animate().scale(duration: 300.ms, curve: Curves.easeOut)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String step,
    required String title,
    required Widget content,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  radius: 14,
                  child: Text(step, 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
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
      return;
    }

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("Utilisateur non connecté.");
      }

      final timeParts = _selectedCreneau!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final salonStartTime = tz.TZDateTime(
        _salonLocation!,
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hour,
        minute,
      );

      final utcStartTime = salonStartTime.toUtc();
      final utcEndTime = salonStartTime.add(_selectedService!.duration).toUtc();

      final clientDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final clientName = clientDoc.data()?['nom'] as String? ?? 'Client inconnu';

      final coiffeurName = _coiffeurs
          .firstWhere((c) => c.id == _selectedCoiffeurId,
              orElse: () => Coiffeur(id: '', name: 'Inconnu', icon: Icons.error, color: Colors.red))
          .name;

      await _firestore.collection('appointments').add({
        'client_user_id': currentUser.uid,
        'client_name': clientName,
        'coiffeur_user_id': _selectedCoiffeurId,
        'coiffeur_name': coiffeurName,
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PlanningPage()),
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
    }
  }
}

