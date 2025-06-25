import 'package:flutter/material.dart';
import 'package:soifapp/models/haircut_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importer Supabase

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
  final SupabaseClient _supabase =
      Supabase.instance.client; // Instance de Supabase

  // Helper pour afficher l'image du service ou une icône par défaut
  Widget _buildServiceImage(HaircutService service, BuildContext context) {
    final theme = Theme.of(context);

    if (service.imagePlaceholder.isNotEmpty) {
      try {
        final imageUrl = _supabase.storage
            .from('service.images') // Assurez-vous que c'est le bon bucket
            .getPublicUrl(service.imagePlaceholder);

        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2.0));
            },
            errorBuilder: (context, error, stackTrace) {
              print("Erreur chargement image service (select service): $error");
              return _buildDefaultServiceIcon(service, theme);
            },
          ),
        );
      } catch (e) {
        print("Erreur construction URL image service (select service): $e");
        return _buildDefaultServiceIcon(service, theme);
      }
    }
    return _buildDefaultServiceIcon(service, theme);
  }

  Widget _buildDefaultServiceIcon(HaircutService service, ThemeData theme) {
    IconData iconData;
    Color baseColor;

    switch (service.category) {
      case ServiceCategory.femme:
        iconData = Icons.female_rounded;
        baseColor = theme.brightness == Brightness.light
            ? Colors.pink[200]!
            : Colors.pink[700]!;
        break;
      case ServiceCategory.homme:
        iconData = Icons.male_rounded;
        baseColor = theme.brightness == Brightness.light
            ? Colors.blue[200]!
            : Colors.blue[700]!;
        break;
      case ServiceCategory.enfant:
        iconData = Icons.child_care_rounded;
        baseColor = theme.brightness == Brightness.light
            ? Colors.green[200]!
            : Colors.green[700]!;
        break;
      case ServiceCategory.mixte:
      // ignore: unreachable_switch_default
      default:
        iconData = Icons.spa_rounded;
        baseColor = theme.brightness == Brightness.light
            ? Colors.purple[200]!
            : Colors.purple[700]!;
        break;
    }
    return Container(
        // width and height are removed to allow Expanded to control sizing
        decoration: BoxDecoration(
            color: baseColor.withOpacity(0.15)), // Consistent opacity
        child: Center(
            child: Icon(iconData,
                color: baseColor,
                size: 50))); // Consistent icon size and centering
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
      theme.colorScheme.surfaceContainerHighest,
    ];
    if (name == null || name.isEmpty) return theme.colorScheme.surfaceBright;
    return colors[name.hashCode % colors.length];
  }

  Widget _buildSubCategoryCard(
      String subCategoryName, String? subCategoryImagePath) {
    Widget imageWidget;

    if (subCategoryImagePath != null && subCategoryImagePath.isNotEmpty) {
      try {
        final imageUrl = _supabase.storage
            .from('sub.category.images') // Bucket des images de sous-catégories
            .getPublicUrl(subCategoryImagePath);
        imageWidget = Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            print(
                "Erreur chargement image sous-catégorie (select service card): $error");
            // Fallback à l'icône dynamique si l'image ne charge pas
            final icon = _getDynamicIconForSubCategory(subCategoryName);
            final color =
                _getDynamicColorForSubCategory(subCategoryName, context);
            return Container(
                color: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 50));
          },
        );
      } catch (e) {
        print("Erreur construction URL image (select service card): $e");
        // Fallback si l'URL ne peut être construite
        final icon = _getDynamicIconForSubCategory(subCategoryName);
        final color = _getDynamicColorForSubCategory(subCategoryName, context);
        imageWidget = Container(
            color: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 50));
      }
    } else {
      // Pas de chemin d'image, utiliser l'icône dynamique
      final icon = _getDynamicIconForSubCategory(subCategoryName);
      final color = _getDynamicColorForSubCategory(subCategoryName, context);
      imageWidget = Container(
          color: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 50));
    }

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
              child: imageWidget, // Utilise le widget image construit
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                subCategoryName, // Afficher le nom de la sous-catégorie
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .primary, // Utilisation du thème
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

    // Crée une map pour stocker le nom de la sous-catégorie et son image (si disponible)
    final Map<String, String?> subCategoryDetails = {};
    for (var service in relevantServices) {
      final subCategoryName = service.subCategory.trim();
      if (subCategoryName.isNotEmpty) {
        // Si la sous-catégorie n'est pas encore dans la map, ou si elle y est mais sans image,
        // et que le service actuel a une image pour cette sous-catégorie, on l'ajoute/met à jour.
        if (!subCategoryDetails.containsKey(subCategoryName) ||
            (subCategoryDetails[subCategoryName] == null &&
                service.imagePlaceholderSousCategory != null &&
                service.imagePlaceholderSousCategory!.isNotEmpty)) {
          subCategoryDetails[subCategoryName] =
              service.imagePlaceholderSousCategory;
        }
      }
    }

    final List<String> displayableSubCategoryNames =
        subCategoryDetails.keys.toList();

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
        final imagePath = subCategoryDetails[subCategoryName];
        return _buildSubCategoryCard(subCategoryName, imagePath);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSubCategoryName ?? 'Choisissez un Service'),
        // backgroundColor: Colors.pink[100], // Supprimé pour utiliser le thème
        // iconTheme: IconThemeData(color: Colors.pink[700]), // Supprimé pour utiliser le thème
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
              borderColor: Theme.of(context).colorScheme.outline,
              selectedBorderColor: Theme.of(context).colorScheme.primary,
              selectedColor: Theme.of(context).colorScheme.onPrimary,
              fillColor: Theme.of(context).colorScheme.primary,
              color: Theme.of(context).colorScheme.primary,
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
    }).toList();

    if (servicesToList.isEmpty) {
      return Center(
          child: Text('Aucun service pour cette sous-catégorie.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Nombre de colonnes
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio:
            0.9, // Match sub-category card aspect ratio for consistency
      ),
      itemCount: servicesToList.length,
      itemBuilder: (context, index) {
        final service = servicesToList[index];
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.pop(context, service);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  // For the image or icon
                  child: _buildServiceImage(
                      service, context), // Affiche l'image ou l'icône
                ),
                Padding(
                  // For the text content, similar to sub-category card
                  padding: const EdgeInsets.all(10.0), // Consistent padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Center content vertically in padding
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Center content horizontally
                    children: [
                      Text(
                        // Price and Duration first
                        '${service.price.toStringAsFixed(2)} € - ${service.duration.inMinutes} min',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary, // Style as secondary info
                          fontSize: 12,
                        ),
                        maxLines: 1, // Prefer single line for this info
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4), // Spacer
                      Text(
                        // Service Name
                        service.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 15, // Match sub-category name font size
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
