import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Assurez-vous que intl est importé
import 'package:soifapp/manage_appointments_page.dart';
import 'package:soifapp/models/haircut_service.dart';
import 'package:soifapp/planning_page.dart'; // Importer la nouvelle page Planning
import 'package:soifapp/salon_location_page.dart'; // Importer la page Localisation
import 'package:soifapp/settings_page.dart'; // Importer la page Paramètres
import 'package:soifapp/widgets/modern_bottom_nav_bar.dart'; // Importer le widget refactorisé

import 'package:soifapp/select_service_page.dart'; // Importer la nouvelle page de sélection

// Classe pour représenter un coiffeur avec plus de détails
class Coiffeur {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  Coiffeur(
      {required this.id,
      required this.name,
      required this.icon,
      required this.color});
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

  // Données fictives pour les services
  final List<HaircutService> _services = [
    HaircutService(
        id: 'cf1',
        name: 'Coupe & Brushing Femme',
        duration: const Duration(minutes: 60),
        price: 55.0,
        subCategory: 'Coupes & Coiffages',
        category: ServiceCategory.femme,
        imagePlaceholder: 'femme_brushing'),
    HaircutService(
        id: 'cf1b',
        name: 'Brushing Simple',
        duration: const Duration(minutes: 30),
        price: 25.0,
        subCategory: 'Coupes & Coiffages',
        category: ServiceCategory.femme,
        imagePlaceholder: 'femme_brushing_simple'),
    HaircutService(
        id: 'cf2',
        name: 'Couleur Femme (racines)',
        duration: const Duration(hours: 1, minutes: 30),
        price: 70.0,
        subCategory: 'Techniques Couleur',
        category: ServiceCategory.femme,
        imagePlaceholder: 'femme_couleur'),
    HaircutService(
        id: 'cf3',
        name: 'Mèches / Balayage',
        duration: const Duration(hours: 2),
        price: 90.0,
        subCategory: 'Techniques Couleur',
        category: ServiceCategory.femme,
        imagePlaceholder: 'femme_meches'),
    HaircutService(
        id: 'ch1',
        name: 'Coupe Homme Classique',
        duration: const Duration(minutes: 30),
        price: 25.0,
        subCategory: 'Coupes',
        category: ServiceCategory.homme,
        imagePlaceholder: 'homme_classique'),
    HaircutService(
        id: 'ch1b',
        name: 'Dégradé Américain',
        duration: const Duration(minutes: 45),
        price: 30.0,
        subCategory: 'Coupes',
        category: ServiceCategory.homme,
        imagePlaceholder: 'homme_degrade'),
    HaircutService(
        id: 'ch2',
        name: 'Coupe Homme + Barbe',
        duration: const Duration(minutes: 45),
        price: 35.0,
        subCategory: 'Barbe & Rasage', // Ou 'Forfaits'
        category: ServiceCategory.homme,
        imagePlaceholder: 'homme_barbe'),
    HaircutService(
        id: 'ch3',
        name: 'Taille de Barbe',
        duration: const Duration(minutes: 20),
        price: 15.0,
        subCategory: 'Barbe & Rasage',
        category: ServiceCategory.homme,
        imagePlaceholder: 'homme_barbe_taille'),
    HaircutService(
        id: 'ce1',
        name: 'Coupe Enfant (-10 ans)',
        duration: const Duration(minutes: 30),
        price: 18.0,
        subCategory: 'Coupes Enfant',
        category: ServiceCategory.enfant,
        imagePlaceholder: 'enfant_coupe'),
    HaircutService(
        id: 'mix1',
        name: 'Shampoing Traitant Spécifique',
        duration: const Duration(minutes: 20),
        price: 15.0,
        subCategory: 'Soins Capillaires',
        category: ServiceCategory.mixte,
        imagePlaceholder: 'mixte_soin'),
  ];

  // Nouvelle liste de coiffeurs avec icônes et couleurs
  final List<Coiffeur> _coiffeurs = [
    Coiffeur(
        id: 'c1',
        name: 'Sophie',
        icon: Icons.female_rounded,
        color: Colors.pinkAccent[100]!),
    Coiffeur(
        id: 'c2',
        name: 'Julien',
        icon: Icons.male_rounded,
        color: Colors.blueAccent[100]!),
    Coiffeur(
        id: 'c3',
        name: 'Chloé',
        icon: Icons.face_retouching_natural_rounded,
        color: Colors.purpleAccent[100]!),
    Coiffeur(
        id: 'c4',
        name: 'Marc',
        icon: Icons.boy_rounded,
        color: Colors.greenAccent[100]!),
    Coiffeur(
        id: 'c5',
        name: 'Léa',
        icon: Icons.girl_rounded,
        color: Colors.orangeAccent[100]!),
    Coiffeur(
        id: 'c6',
        name: 'Antoine',
        icon: Icons.man_3_rounded,
        color: Colors.tealAccent[100]!),
    Coiffeur(
        id: 'c7',
        name: 'Manon',
        icon: Icons.woman_2_rounded,
        color: Colors.redAccent[100]!),
  ];
  final List<String> _creneauxDisponibles = [
    '09:00 - 09:30',
    '09:30 - 10:00',
    '10:00 - 10:30',
    '10:30 - 11:00',
    '11:00 - 11:30',
    '11:30 - 12:00',
    '14:00 - 14:30',
    '14:30 - 15:00',
    '15:00 - 15:30',
    '15:30 - 16:00',
    '16:00 - 16:30',
    '16:30 - 17:00',
  ];

  // Index pour la barre de navigation inférieure
  int _currentIndex = 0;

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
  }

  void _navigateToSelectServicePage() async {
    final HaircutService? selectedService =
        await Navigator.push<HaircutService>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectServicePage(allServices: _services),
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
    }
  }

  Widget _buildHorizontalCalendar() {
    List<Widget> dateWidgets = [];
    DateTime today = DateTime.now();

    for (int i = 0; i < 14; i++) {
      DateTime date = today.add(Duration(days: i));
      bool isSelected = _selectedDate != null &&
          date.year == _selectedDate!.year &&
          date.month == _selectedDate!.month &&
          date.day == _selectedDate!.day;

      dateWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
              _selectedCreneau =
                  null; // Réinitialiser le créneau si la date change
            });
          },
          child: Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  DateFormat.E('fr_FR')
                      .format(date)
                      .substring(0, 3), // Ex: "Lun"
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 70, // Hauteur du calendrier horizontal
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: dateWidgets,
      ),
    );
  }

  Widget _buildCoiffeurSelector() {
    return SizedBox(
      height: 120, // Hauteur pour l'avatar et le nom
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _coiffeurs.length,
        itemBuilder: (context, index) {
          final coiffeur = _coiffeurs[index];
          final isSelected = _selectedCoiffeurId == coiffeur.id;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCoiffeurId = coiffeur.id;
                _selectedCreneau = null; // Réinitialiser le créneau
              });
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(3.0), // Espace pour la bordure
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.pink[400]!, width: 2.5)
                          : Border.all(color: Colors.transparent, width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: coiffeur.color.withOpacity(0.8),
                      child: Icon(coiffeur.icon, size: 30, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coiffeur.name,
                    style: TextStyle(
                        color: isSelected ? Colors.pink[700] : Colors.grey[800],
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
    if (index == _currentIndex && index == 0)
      return; // Déjà sur RDV et on clique sur RDV

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
        title: const Text('Réservation de Créneau'),
        // Les couleurs de l'AppBar sont maintenant gérées par AppBarTheme dans main.dart
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Sélecteur de date
            Text('1. Choisissez une date :',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 15),
            _buildHorizontalCalendar(), // Ajout du calendrier horizontal ici
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.calendar_today,
                    color: Theme.of(context).colorScheme.onPrimary),
                label: Text(
                  _selectedDate == null
                      ? 'Sélectionner une date'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => _pickDate(context),
              ),
            ),
            const SizedBox(height: 30),

            // Choix du service
            Text('2. Choisissez un service :',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _navigateToSelectServicePage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedService == null
                            ? 'Cliquez pour choisir un service'
                            : '${_selectedService!.name} (${_selectedService!.duration.inMinutes} min)',
                        style: TextStyle(
                          color: _selectedService == null
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.7)
                              : Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.7),
                        size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Choix du coiffeur
            if (_selectedDate != null && _selectedService != null) ...[
              Text('3. Choisissez votre coiffeur/coiffeuse :',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 15),
              _buildCoiffeurSelector(), // Nouveau sélecteur de coiffeur
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
              const SizedBox(height: 15),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: _creneauxDisponibles.map((creneau) {
                  final isSelected = _selectedCreneau == creneau;
                  return ChoiceChip(
                    label: Text(creneau,
                        style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary)),
                    selected: isSelected,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCreneau = selected ? creneau : null;
                      });
                    },
                  );
                }).toList(),
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
                      ? () {
                          final String coiffeurName = _coiffeurs
                              .firstWhere((c) => c.id == _selectedCoiffeurId)
                              .name;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'RDV pour ${_selectedService!.name} avec $coiffeurName le ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} à $_selectedCreneau. (Fictif)'),
                              backgroundColor: Colors.green[
                                  600], // Ou une couleur de succès du thème
                            ),
                          );
                          // Naviguer vers la page de gestion des RDV
                          Navigator.pushReplacement(
                            // Ou Navigator.push si vous voulez pouvoir revenir
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ManageAppointmentsPage()),
                          );
                        }
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
}
