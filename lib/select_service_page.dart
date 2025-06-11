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

  // Définition des sous-catégories avec icônes et couleurs
  // Utilisé pour générer les cartes de sous-catégories
  static const Map<ServiceCategory, List<SubCategoryDisplay>>
      _subCategoryOptions = {
    ServiceCategory.femme: [
      SubCategoryDisplay(
          name: 'Coupes & Coiffages',
          icon: Icons.content_cut,
          color: Color(0xFFEC407A)), // Pink
      SubCategoryDisplay(
          name: 'Techniques Couleur',
          icon: Icons.brush,
          color: Color(0xFFAB47BC)), // Purple
      SubCategoryDisplay(
          name: 'Soins Capillaires',
          icon: Icons.spa,
          color: Color(0xFF26A69A)), // Teal
    ],
    ServiceCategory.homme: [
      SubCategoryDisplay(
          name: 'Coupes', icon: Icons.cut, color: Color(0xFF42A5F5)), // Blue
      SubCategoryDisplay(
          name: 'Barbe & Rasage',
          icon: Icons.face_retouching_natural,
          color: Color(0xFF8D6E63)), // Brown
      SubCategoryDisplay(
          name: 'Soins Capillaires',
          icon: Icons.spa,
          color: Color(0xFF26A69A)), // Teal
    ],
    ServiceCategory.enfant: [
      SubCategoryDisplay(
          name: 'Coupes Enfant',
          icon: Icons.child_friendly,
          color: Color(0xFF66BB6A)), // Green
    ],
    // Mixte n'est pas une catégorie principale de sélection ici
  };

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
  ];

  Widget _buildSubCategoryCard(SubCategoryDisplay subCategoryDisplay) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSubCategoryName = subCategoryDisplay.name;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: subCategoryDisplay.color.withOpacity(0.15),
                child: Icon(subCategoryDisplay.icon,
                    color: subCategoryDisplay.color, size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                subCategoryDisplay.name,
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
    final List<SubCategoryDisplay> currentSubCategories =
        _subCategoryOptions[_selectedMainCategory] ?? [];

    final List<SubCategoryDisplay> displayableSubCategories =
        currentSubCategories.where((scd) {
      return widget.allServices.any((service) {
        if (service.subCategory != scd.name) return false;
        if (service.category == _selectedMainCategory) return true;
        if (service.category == ServiceCategory.mixte) {
          return _subCategoryOptions[_selectedMainCategory]
                  ?.any((s) => s.name == service.subCategory) ??
              false;
        }
        return false;
      });
    }).toList();

    if (displayableSubCategories.isEmpty) {
      return Center(
          child: Text('Aucun service disponible pour cette catégorie.',
              style: TextStyle(color: Colors.pink[300], fontSize: 16)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.9, // Ajustez pour la proportion des cartes
      ),
      itemCount: displayableSubCategories.length,
      itemBuilder: (context, index) {
        final subCategoryDisplay = displayableSubCategories[index];
        return _buildSubCategoryCard(subCategoryDisplay);
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
                  case ServiceCategory.mixte: // Ne devrait pas être ici
                    text = '';
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
      if (service.subCategory != _selectedSubCategoryName) return false;
      if (service.category == _selectedMainCategory) return true;
      if (service.category == ServiceCategory.mixte) {
        return _subCategoryOptions[_selectedMainCategory]
                ?.any((scd) => scd.name == service.subCategory) ??
            false;
      }
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

// Classe simple pour la structure des données d'affichage des sous-catégories
class SubCategoryDisplay {
  final String name;
  final IconData icon;
  final Color color;

  const SubCategoryDisplay(
      {required this.name, required this.icon, required this.color});
}
