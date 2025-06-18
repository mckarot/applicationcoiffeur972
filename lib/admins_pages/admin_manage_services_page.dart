import 'package:flutter/material.dart';
import 'package:soifapp/models/haircut_service.dart'; // Assurez-vous que le chemin est correct
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminManageServicesPage extends StatefulWidget {
  const AdminManageServicesPage({super.key});

  @override
  State<AdminManageServicesPage> createState() =>
      _AdminManageServicesPageState();
}

class _AdminManageServicesPageState extends State<AdminManageServicesPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<HaircutService> _services = [];
  bool _isLoading = true;
  String? _errorMessage;

  // États pour la sélection, similaires à SelectServicePage
  ServiceCategory _selectedMainCategory =
      ServiceCategory.femme; // Catégorie par défaut
  String? _selectedSubCategoryName;
  final List<ServiceCategory> _displayCategories = [
    ServiceCategory.femme,
    ServiceCategory.homme,
    ServiceCategory.enfant,
    ServiceCategory.mixte,
  ];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<Map<String, dynamic>> servicesData =
          await _supabase.from('haircut_services').select().order('name');

      if (mounted) {
        setState(() {
          _services = servicesData
              .map((data) => HaircutService.fromSupabase(data))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Erreur fetchServices (admin): $e');
        setState(() {
          _errorMessage = 'Impossible de charger les services.';
          _isLoading = false;
        });
      }
    }
  }

  // Helper pour l'affichage de l'image du service (similaire à SelectServicePage)
  Widget _buildServiceImage(HaircutService service, BuildContext context) {
    if (service.imagePlaceholder.isNotEmpty) {
      try {
        final imageUrl = _supabase.storage
            .from('service.images')
            .getPublicUrl(service.imagePlaceholder);

        // Utilisation de ClipRRect pour s'assurer que l'image respecte les coins arrondis
        // si la carte elle-même ne le fait pas assez pour l'image (bien que Clip.antiAlias sur Card aide).
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
            print('Erreur chargement image réseau (admin): $error');
            return _buildDefaultServiceIcon(service, context);
          },
        );
      } catch (e) {
        print("Erreur construction URL image (admin): $e");
        return _buildDefaultServiceIcon(service, context);
      }
    }
    return _buildDefaultServiceIcon(service, context);
  }

  Widget _buildDefaultServiceIcon(
      HaircutService service, BuildContext context) {
    IconData iconData;
    Color baseColor; // Couleur de base pour l'icône et le fond
    final theme = Theme.of(context);

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
        iconData = Icons.spa_rounded;
        baseColor = theme.brightness == Brightness.light
            ? Colors.purple[200]!
            : Colors.purple[700]!;
        break;
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey,
      child: Icon(iconData, color: Colors.white, size: 30), // Original
    ); // Ce widget sera remplacé par un Container pour correspondre au style des cartes de sous-catégories
    return Container(
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.20), // Fond avec opacité
      ),
      child: Center(child: Icon(iconData, color: baseColor, size: 50)),
    );
  }

  Future<void> _deleteService(String serviceId, String serviceName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
              'Voulez-vous vraiment supprimer le service "$serviceName" ? Cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _supabase.from('haircut_services').delete().eq('id', serviceId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Service "$serviceName" supprimé.'),
                backgroundColor: Colors.green),
          );
          _fetchServices(); // Recharger la liste
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur lors de la suppression: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // --- Méthodes de construction de l'UI adaptées de SelectServicePage ---

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
      theme.colorScheme.surfaceContainerHighest, // ou surfaceVariant
    ];
    if (name == null || name.isEmpty)
      return theme.colorScheme.surfaceBright; // ou surface
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
                color: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                subCategoryName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
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

  Widget _buildSubCategorySelectionGrid() {
    final relevantServices = _services.where((service) {
      return service.category == _selectedMainCategory ||
          service.category == ServiceCategory.mixte;
    }).toList();

    final Set<String> uniqueSubCategoryNames =
        relevantServices.map((service) => service.subCategory.trim()).toSet();

    final List<String> displayableSubCategoryNames =
        uniqueSubCategoryNames.where((name) => name.isNotEmpty).toList();
    displayableSubCategoryNames
        .sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (displayableSubCategoryNames.isEmpty) {
      return const Center(
          child: Text("Aucune sous-catégorie pour cette sélection."));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.9,
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
        title: Text(_selectedSubCategoryName ?? 'Gérer les Services'),
        leading: _selectedSubCategoryName != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  setState(() {
                    _selectedSubCategoryName = null;
                  });
                },
              )
            : null, // Utilise le bouton retour par défaut de la navigation si non null
        // Laisser null pour le comportement par défaut (menu hamburger ou bouton retour)
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : _services.isEmpty
                  ? const Center(child: Text('Aucun service à gérer.'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 8.0),
                          child: ToggleButtons(
                            borderColor: Theme.of(context).colorScheme.outline,
                            selectedBorderColor:
                                Theme.of(context).colorScheme.primary,
                            selectedColor:
                                Theme.of(context).colorScheme.onPrimary,
                            fillColor: Theme.of(context).colorScheme.primary,
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8.0),
                            isSelected: _displayCategories
                                .map((category) =>
                                    _selectedMainCategory == category)
                                .toList(),
                            onPressed: (int index) {
                              setState(() {
                                _selectedMainCategory =
                                    _displayCategories[index];
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
                                  break;
                              }
                              return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Text(text));
                            }).toList(),
                          ),
                        ),
                        Expanded(
                          child: _selectedSubCategoryName == null
                              ? _buildSubCategorySelectionGrid()
                              : _buildServiceListForDeletion(),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildServiceListForDeletion() {
    final List<HaircutService> servicesToList = _services.where((service) {
      bool subCategoryMatch = service.subCategory.trim().toLowerCase() ==
          _selectedSubCategoryName?.trim().toLowerCase();
      if (!subCategoryMatch) return false;
      bool categoryMatch = service.category == _selectedMainCategory ||
          service.category == ServiceCategory.mixte;
      return categoryMatch;
    }).toList();

    if (servicesToList.isEmpty) {
      return const Center(
          child: Text('Aucun service pour cette sous-catégorie.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchServices, // Permet de rafraîchir la liste complète
      child: GridView.builder(
        padding: const EdgeInsets.all(12.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Nombre de colonnes
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio:
              0.75, // Ajusté pour plus de contenu (image, textes, bouton)
        ),
        itemCount: servicesToList.length,
        itemBuilder: (context, index) {
          final service = servicesToList[index];
          return Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    // Ce container assure que _buildServiceImage remplit l'espace.
                    // Si _buildServiceImage retourne un widget qui ne s'étend pas,
                    // ce Container peut aider avec alignment ou un fond.
                    // color: Colors.grey[200], // Placeholder background if needed
                    child: _buildServiceImage(service, context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        service.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${service.price.toStringAsFixed(2)} € - ${service.duration.inMinutes} min',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error, size: 26),
                    tooltip: 'Supprimer ce service',
                    onPressed: () => _deleteService(service.id, service.name),
                    padding: const EdgeInsets.only(bottom: 6.0),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
