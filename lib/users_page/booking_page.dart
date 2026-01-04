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
import 'package:flutter/gestures.dart';

import 'widgets/date_selector.dart';
import 'widgets/service_selector.dart';
import 'widgets/slot_selector.dart';

// Fonctions d'aide existantes (inchangées)
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
  final IconData icon;
  final Color color;
  final List<String>? specialites;
  final String? descriptionBio;
  final String? photoUrl;

  Coiffeur({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.specialites,
    this.descriptionBio,
    this.photoUrl,
  });

  factory Coiffeur.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final userId = doc.id;
    return Coiffeur(
      id: userId,
      name: data['nom'] ?? 'Coiffeur inconnu',
      icon: _getDynamicIconForCoiffeur(userId),
      color: _getDynamicColorForCoiffeur(userId),
      specialites: data['specialites'] != null
          ? List<String>.from(data['specialites'])
          : null,
      descriptionBio: data['description_bio'] as String?,
      photoUrl: data['photo_url'] as String?,
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
  String? _selectedCoiffeurId;
  String? _selectedCreneau;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Coiffeur> _coiffeurs = [];
  bool _isLoadingCoiffeurs = true;
  String? _coiffeursError;
  List<HaircutService> _allServices = [];
  bool _isLoadingServices = true;
  String? _servicesError;
  List<SubCategory> _allSubCategories = [];
  bool _isLoadingSubCategories = true;
  bool _imagesPrecached = false;

  List<String> _dynamicAvailableSlots = [];
  bool _isLoadingSlots = false;
  String? _slotsError;

  int _currentIndex = 0;
  static const int slotIncrementMinutes = 15;
  tz.Location? _salonLocation;

  @override
  void initState() {
    super.initState();
    _initializeSalonLocation();
    _fetchAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached &&
        !_isLoadingCoiffeurs &&
        !_isLoadingSubCategories &&
        !_isLoadingServices) {
      _precacheAllImages();
      _imagesPrecached = true;
    }
  }

  void _precacheAllImages() {
    if (!mounted) return;
    for (final coiffeur in _coiffeurs) {
      if (coiffeur.photoUrl != null && coiffeur.photoUrl!.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(coiffeur.photoUrl!), context);
      }
    }
    for (final subCategory in _allSubCategories) {
      if (subCategory.imageUrl != null && subCategory.imageUrl!.isNotEmpty) {
        precacheImage(
            CachedNetworkImageProvider(subCategory.imageUrl!), context);
      }
    }
    for (final service in _allServices) {
      if (service.imagePlaceholder.isNotEmpty) {
        precacheImage(
            CachedNetworkImageProvider(service.imagePlaceholder), context);
      }
    }
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchCoiffeurs(),
      _fetchServices(),
      _fetchSubCategories(),
    ]);
    if (mounted && !_imagesPrecached) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _precacheAllImages();
        _imagesPrecached = true;
      });
    }
  }

  Future<void> _initializeSalonLocation() async {
    try {
      _salonLocation = tz.getLocation('America/Martinique');
    } catch (e) {
      print("Erreur initialisation fuseau horaire salon (BookingPage): $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Erreur de configuration du fuseau horaire. La réservation pourrait être affectée.")));
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
      if (mounted) {
        setState(() {
          _coiffeurs = coiffeursSnapshot.docs
              .map((doc) => Coiffeur.fromFirestore(doc))
              .toList();
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
      }
    }
  }

  Future<void> _fetchSubCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSubCategories = true;
    });

    try {
      final snapshot = await _firestore.collection('sub_categories').get();
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

      final DateTime dayStartUtc =
          DateTime.utc(selectedDate.year, selectedDate.month, selectedDate.day);
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

      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('coiffeur_user_id', isEqualTo: coiffeurId)
          .where('start_time', isLessThan: dayEndUtc)
          .get();
      final List<Map<String, dynamic>> appointmentsData = appointmentsSnapshot
          .docs
          .where((doc) =>
              (doc.data()['status'] ?? 'confirmed') != 'cancelled_by_client')
          .map((doc) => doc.data())
          .where((rdv) =>
              (rdv['end_time'] as Timestamp).toDate().isAfter(dayStartUtc))
          .toList();

      final absencesSnapshot = await _firestore
          .collection('coiffeur_absences')
          .where('coiffeur_user_id', isEqualTo: coiffeurId)
          .where('start_time', isLessThan: dayEndUtc)
          .get();
      final List<Map<String, dynamic>> absencesData = absencesSnapshot.docs
          .map((doc) => doc.data())
          .where((absence) =>
              (absence['end_time'] as Timestamp).toDate().isAfter(dayStartUtc))
          .toList();

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

        while (potentialSlotStart
                .add(serviceDuration)
                .isBefore(availabilityEnd) ||
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
      }
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) => Theme(data: Theme.of(context), child: child!),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedCreneau = null;
      });
      _fetchAvailableSlots();
    }
  }

  void _navigateToSelectServicePage() async {
    final HaircutService? selectedService = await Navigator.push<HaircutService>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectServicePage(
          allServices: _allServices,
          allSubCategories: _allSubCategories,
          onRefresh: () async {
            await _fetchServices();
            return _allServices;
          },
        ),
      ),
    );

    if (selectedService != null) {
      setState(() {
        _selectedService = selectedService;
        _selectedCoiffeurId = null;
        _selectedCreneau = null;
      });
      _fetchAvailableSlots();
    }
  }

  Widget _buildCoiffeurSelector() {
    if (_isLoadingCoiffeurs) {
      return Center(
          child: SpinKitFadingCircle(
              color: Theme.of(context).colorScheme.primary, size: 50.0));
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
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: { PointerDeviceKind.touch, PointerDeviceKind.mouse },
        ),
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
                      builder: (context) =>
                          CoiffeurDetailsPage(coiffeur: coiffeur)),
                );
                if (selectedId != null && mounted) {
                  setState(() {
                    _selectedCoiffeurId = selectedId;
                    _selectedCreneau = null;
                  });
                  _fetchAvailableSlots();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                                        radius: 35, backgroundImage: imageProvider),
                                placeholder: (context, url) =>
                                    const CircleAvatar(
                                        radius: 35,
                                        backgroundColor: Colors.grey,
                                        child: SpinKitFadingCircle(
                                            color: Colors.white, size: 30.0)),
                                errorWidget: (context, url, error) =>
                                    CircleAvatar(
                                        radius: 35,
                                        backgroundColor:
                                            coiffeur.color.withOpacity(0.8),
                                        child: Icon(coiffeur.icon,
                                            size: 30, color: Colors.white)),
                              )
                            : CircleAvatar(
                                radius: 35,
                                backgroundColor: coiffeur.color.withOpacity(0.8),
                                child: Icon(coiffeur.icon,
                                    size: 30, color: Colors.white)),
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
      ),
    );
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex && index == 0) return;

    switch (index) {
      case 1:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const PlanningPage()));
        break;
      case 2:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const SalonLocationPage()));
        break;
      case 3:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const SettingsPage()));
        break;
      default: // index 0
        setState(() => _currentIndex = index);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Réservation'),
        actions: const [LogoutButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _BookingDesktopLayout(state: this);
          } else {
            return _BookingMobileLayout(state: this);
          }
        },
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 200, // Hauteur minimale pour harmoniser les cartes
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    radius: 14,
                    child:
                        Text(step, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: content),
            ],
          ),
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
          const SnackBar(content: Text('Veuillez compléter toutes les sélections.')));
      return;
    }
    if (_salonLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur de configuration du fuseau horaire. Réservation annulée.')));
      return;
    }

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("Utilisateur non connecté.");

      final timeParts = _selectedCreneau!.split(':');
      final salonStartTime = tz.TZDateTime(_salonLocation!, _selectedDate!.year,
          _selectedDate!.month, _selectedDate!.day, int.parse(timeParts[0]), int.parse(timeParts[1]));

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Rendez-vous confirmé avec succès !'),
            backgroundColor: Colors.green[600]));
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const PlanningPage()));
      }
    } catch (e) {
      if (mounted) {
        print("Erreur lors de la confirmation du RDV: $e");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la confirmation: $e')));
      }
    }
  }
}

// Layout pour Mobile
class _BookingMobileLayout extends StatelessWidget {
  final _BookingPageState state;
  const _BookingMobileLayout({required this.state});

  @override
  Widget build(BuildContext context) {
    final bool isLoading =
        state._isLoadingServices || state._isLoadingSubCategories;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          state._buildSectionCard(
            context: context,
            step: '1',
            title: 'Choisissez une date',
            content: DateSelector(
              selectedDate: state._selectedDate,
              onDateSelected: (date) {
                state.setState(() {
                  state._selectedDate = date;
                  state._selectedCreneau = null;
                });
                state._fetchAvailableSlots();
              },
              onPickDateTap: state._pickDate,
            ),
          ),
          state._buildSectionCard(
            context: context,
            step: '2',
            title: 'Choisissez une prestation',
            content: isLoading
                ? const Center(child: CircularProgressIndicator())
                : state._servicesError != null
                    ? Center(
                        child: Text(state._servicesError!,
                            style:
                                TextStyle(color: Theme.of(context).colorScheme.error)))
                    : ServiceSelector(
                        selectedService: state._selectedService,
                        onTap: state._navigateToSelectServicePage,
                      ),
          ),
          if (state._selectedDate != null && state._selectedService != null)
            state._buildSectionCard(
              context: context,
              step: '3',
              title: 'Choisissez un coiffeur',
              content: state._buildCoiffeurSelector(),
            ).animate().fadeIn(duration: 400.ms),
          if (state._selectedDate != null &&
              state._selectedService != null &&
              state._selectedCoiffeurId != null)
            state._buildSectionCard(
              context: context,
              step: '4',
              title: 'Choisissez un créneau',
              content: Center(
                child: SlotSelector(
                  availableSlots: state._dynamicAvailableSlots,
                  selectedSlot: state._selectedCreneau,
                  onSlotSelected: (slot) {
                    state.setState(() => state._selectedCreneau = slot);
                  },
                  selectedService: state._selectedService,
                  isLoading: state._isLoadingSlots,
                  error: state._slotsError,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 80), // Espace pour le bouton
        ],
      ),
    );
  }
}

// Layout pour Desktop
class _BookingDesktopLayout extends StatelessWidget {
  final _BookingPageState state;
  const _BookingDesktopLayout({required this.state});

  @override
  Widget build(BuildContext context) {
    final bool isLoading =
        state._isLoadingServices || state._isLoadingSubCategories;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Wrap(
        spacing: 16, // Espace horizontal entre les cartes
        runSpacing: 16, // Espace vertical entre les lignes de cartes
        alignment: WrapAlignment.start,
        children: <Widget>[
          _buildWrappedCard(
            context: context,
            child: state._buildSectionCard(
              context: context,
              step: '1',
              title: 'Choisissez une date',
              content: DateSelector(
                selectedDate: state._selectedDate,
                onDateSelected: (date) {
                  state.setState(() {
                    state._selectedDate = date;
                    state._selectedCreneau = null;
                  });
                  state._fetchAvailableSlots();
                },
                onPickDateTap: state._pickDate,
              ),
            ),
          ),
          _buildWrappedCard(
            context: context,
            child: state._buildSectionCard(
              context: context,
              step: '2',
              title: 'Choisissez une prestation',
              content: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state._servicesError != null
                      ? Center(child: Text(state._servicesError!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
                      : ServiceSelector(
                          selectedService: state._selectedService,
                          onTap: state._navigateToSelectServicePage,
                        ),
            ),
          ),
          if (state._selectedDate != null && state._selectedService != null)
            _buildWrappedCard(
              context: context,
              child: state._buildSectionCard(
                context: context,
                step: '3',
                title: 'Choisissez un coiffeur',
                content: state._buildCoiffeurSelector(),
              ),
            ).animate().fadeIn(duration: 400.ms),
          if (state._selectedDate != null &&
              state._selectedService != null &&
              state._selectedCoiffeurId != null)
            _buildSlotSelectorCard(
              context: context,
              child: state._buildSectionCard(
                context: context,
                step: '4',
                title: 'Choisissez un créneau',
                content: Center(
                  child: SlotSelector(
                    availableSlots: state._dynamicAvailableSlots,
                    selectedSlot: state._selectedCreneau,
                    onSlotSelected: (slot) {
                      state.setState(() => state._selectedCreneau = slot);
                    },
                    selectedService: state._selectedService,
                    isLoading: state._isLoadingSlots,
                    error: state._slotsError,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildWrappedCard({required BuildContext context, required Widget child}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 400, // Largeur fixe pour chaque carte
        maxWidth: 400, // Même largeur maximale pour uniformité
        minHeight: 300, // Hauteur minimale pour chaque carte
        maxHeight: 600, // Hauteur maximale pour chaque carte
      ),
      child: child,
    );
  }

  Widget _buildSlotSelectorCard({required BuildContext context, required Widget child}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 500, // Largeur plus grande pour la carte des créneaux horaires
        maxWidth: 500, // Même largeur maximale pour uniformité
        minHeight: 300, // Hauteur minimale pour chaque carte
        maxHeight: 600, // Hauteur maximale pour chaque carte
      ),
      child: child,
    );
  }
}

