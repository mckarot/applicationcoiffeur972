import 'package:flutter/material.dart';
import 'package:soifapp/models/haircut_service.dart';

class SelectServicePage extends StatefulWidget {
  final List<HaircutService> allServices;

  const SelectServicePage({super.key, required this.allServices});

  @override
  State<SelectServicePage> createState() => _SelectServicePageState();
}

class _SelectServicePageState extends State<SelectServicePage> {
  ServiceCategory _selectedMainCategory =
      ServiceCategory.femme; // Catégorie par défaut
  String? _selectedSubCategoryName;

  // Helper pour obtenir une couleur/icône basée sur le placeholder
  Widget _buildServiceImage(HaircutService service) {
    IconData iconData;
    Color color;

    switch (service.category) {
      case ServiceCategory.femme:
        iconData = Icons.female_rounded;
        color = Colors.pink[200]!;
        break;
      case ServiceCategory.homme:
        iconData = Icons.male_rounded;
        color = Colors.blue[200]!;
        break;
      case ServiceCategory.enfant:
        iconData = Icons.child_care_rounded;
        color = Colors.green[200]!;
        break;
      case ServiceCategory.mixte:
        iconData = Icons.spa_rounded;
        color = Colors.purple[200]!;
        break;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: Colors.white, size: 40),
    );
  }

  final List<ServiceCategory> _displayCategories = [
    ServiceCategory.femme,
    ServiceCategory.homme,
    ServiceCategory.enfant,
    ServiceCategory.mixte, // Ajouter Mixte ici
  ];

  // Fonctions pour générer des icônes et couleurs dynamiques pour les sous-catégories
  IconData _getDynamicIconForSubCategory(String? name) {
    final icons = [
      Icons.style_outlined,
      Icons.auto_fix_high_outlined,
      Icons.content_cut_rounded,
      Icons.brush_outlined,
      Icons.spa_outlined,
      Icons.face_retouching_natural_outlined,
      Icons.waves_outlined,
      Icons.color_lens_outlined,
      Icons.category_outlined,
    ];
    if (name == null || name.isEmpty) return Icons.interests_outlined;
    return icons[name.hashCode % icons.length];
  }

  Color _getDynamicColorForSubCategory(String? name, BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      theme.colorScheme.primaryContainer,
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.tertiaryContainer,
      theme.colorScheme.surfaceVariant,
    ];
    if (name == null || name.isEmpty) return theme.colorScheme.surfaceBright;
    return colors[name.hashCode % colors.length];
  }

  Widget _buildSubCategoryCard(String subCategoryName) {
    final icon = _getDynamicIconForSubCategory(subCategoryName);
    final color = _getDynamicColorForSubCategory(subCategoryName, context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSubCategoryName = subCategoryName;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: color.withOpacity(0.15), // Utiliser la couleur dynamique
                child: Icon(icon,
                    color: color, size: 50), // Utiliser l'icône dynamique
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                subCategoryName, // Afficher le nom de la sous-catégorie
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[800],
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategorySelection() {
    // 1. Filtrer les services pour la catégorie principale sélectionnée (ou mixte)
    final relevantServices = widget.allServices.where((service) {
      return service.category == _selectedMainCategory ||
          service.category == ServiceCategory.mixte;
    }).toList();

    // 2. Extraire les noms de sous-catégories uniques de ces services
    final Set<String> uniqueSubCategoryNames =
        relevantServices.map((service) => service.subCategory.trim()).toSet();

    // 3. Filtrer les sous-catégories vides si jamais il y en a
    final List<String> displayableSubCategoryNames =
        uniqueSubCategoryNames.where((name) => name.isNotEmpty).toList();

    // Optionnel: trier les noms des sous-catégories
    displayableSubCategoryNames
        .sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.9, // Ajustez pour la proportion des cartes
      ),
      itemCount: displayableSubCategoryNames.length,
      itemBuilder: (context, index) {
        final subCategoryName = displayableSubCategoryNames[index];
        return _buildSubCategoryCard(subCategoryName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSubCategoryName ?? 'Choisissez un Service'),
        backgroundColor: Colors.pink[100],
        iconTheme: IconThemeData(color: Colors.pink[700]),
        leading: _selectedSubCategoryName != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  setState(() {
                    _selectedSubCategoryName = null;
                  });
                },
              )
            : null, // Utilise le bouton retour par défaut de la navigation
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: ToggleButtons(
              borderColor: Colors.pink[200],
              selectedBorderColor: Colors.pink[400],
              selectedColor: Colors.white,
              fillColor: Colors.pink[300],
              color: Colors.pink[400],
              borderRadius: BorderRadius.circular(8.0),
              isSelected: _displayCategories
                  .map((category) => _selectedMainCategory == category)
                  .toList(),
              onPressed: (int index) {
                setState(() {
                  _selectedMainCategory = _displayCategories[index];
                  _selectedSubCategoryName =
                      null; // Réinitialiser la sous-catégorie
                });
              },
              children: _displayCategories.map((category) {
                String text;
                switch (category) {
                  case ServiceCategory.femme:
                    text = 'Femme';
                    break;
                  case ServiceCategory.homme:
                    text = 'Homme';
                    break;
                  case ServiceCategory.enfant:
                    text = 'Enfant';
                    break;
                  case ServiceCategory.mixte:
                    text = 'Mixte'; // Afficher "Mixte"
                }
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(text));
              }).toList(),
            ),
          ),
          Expanded(
            child: _selectedSubCategoryName == null
                ? _buildSubCategorySelection()
                : _buildServiceListForSubCategory(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceListForSubCategory() {
    final List<HaircutService> servicesToList =
        widget.allServices.where((service) {
      // Comparaison insensible à la casse et aux espaces pour la sous-catégorie
      bool subCategoryMatch = service.subCategory.trim().toLowerCase() ==
          _selectedSubCategoryName?.trim().toLowerCase();

      if (!subCategoryMatch) return false;

      // Le service doit appartenir à la catégorie principale sélectionnée OU être mixte
      bool categoryMatch = service.category == _selectedMainCategory ||
          service.category == ServiceCategory.mixte;
      return categoryMatch;
      return false;
    }).toList();

    if (servicesToList.isEmpty) {
      return Center(
          child: Text('Aucun service pour cette sous-catégorie.',
              style: TextStyle(color: Colors.pink[300], fontSize: 16)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: servicesToList.length,
      itemBuilder: (context, index) {
        final service = servicesToList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          color: Colors.pink[50],
          child: ListTile(
            leading: _buildServiceImage(service),
            title: Text(service.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.pink[700])),
            subtitle: Text(
                'Durée: ${service.duration.inMinutes} min\nPrix: ${service.price.toStringAsFixed(2)} €',
                style: TextStyle(color: Colors.pink[500])),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.pink[300], size: 16),
            isThreeLine: true,
            onTap: () {
              Navigator.pop(
                  context, service); // Retourne le service sélectionné
            },
          ),
        );
      },
    );
  }
}
