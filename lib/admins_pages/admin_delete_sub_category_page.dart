import 'package:flutter/material.dart';
import 'package:soifapp/models/haircut_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDeleteSubCategoryPage extends StatefulWidget {
  const AdminDeleteSubCategoryPage({super.key});

  @override
  State<AdminDeleteSubCategoryPage> createState() =>
      _AdminDeleteSubCategoryPageState();
}

class _AdminDeleteSubCategoryPageState
    extends State<AdminDeleteSubCategoryPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<HaircutService> _services = []; // Pour déduire les sous-catégories
  bool _isLoading = true;
  String? _errorMessage;

  ServiceCategory _selectedMainCategory = ServiceCategory.femme;
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
        print('Erreur fetchServices (delete sub_category page): $e');
        setState(() {
          _errorMessage =
              'Impossible de charger les données pour les sous-catégories.';
          _isLoading = false;
        });
      }
    }
  }

  // --- Fonctions pour l'affichage des cartes de sous-catégories (similaires à AdminManageServicesPage) ---
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
            final icon = _getDynamicIconForSubCategory(subCategoryName);
            final color =
                _getDynamicColorForSubCategory(subCategoryName, context);
            return Container(
                color: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 50));
          },
        );
      } catch (e) {
        final icon = _getDynamicIconForSubCategory(subCategoryName);
        final color = _getDynamicColorForSubCategory(subCategoryName, context);
        imageWidget = Container(
            color: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 50));
      }
    } else {
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
          _confirmDeleteSubCategory(subCategoryName, _selectedMainCategory);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: imageWidget),
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

    final Map<String, String?> subCategoryDetails = {};
    for (var service in relevantServices) {
      final subCategoryName = service.subCategory.trim();
      if (subCategoryName.isNotEmpty) {
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

    if (displayableSubCategoryNames.isEmpty) {
      return const Center(
          child:
              Text("Aucune sous-catégorie à supprimer pour cette sélection."));
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
        final imagePath = subCategoryDetails[subCategoryName];
        return _buildSubCategoryCard(subCategoryName, imagePath);
      },
    );
  }

  Future<void> _confirmDeleteSubCategory(
      String subCategoryName, ServiceCategory mainCategory) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
              'Voulez-vous vraiment supprimer la sous-catégorie "$subCategoryName" (${mainCategory.name}) et TOUS les services qu\'elle contient ? Cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Supprimer Définitivement'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteSubCategoryAndServices(subCategoryName, mainCategory);
    }
  }

  Future<void> _deleteSubCategoryAndServices(
      String subCategoryName, ServiceCategory mainCategory) async {
    setState(() => _isLoading = true);
    try {
      // Récupérer les services à supprimer pour potentiellement supprimer leurs images
      final servicesToDeleteResponse = await _supabase
          .from('haircut_services')
          .select(
              'id, image_placeholder') // On a besoin de l'image_placeholder du service
          .eq('sub_category', subCategoryName)
          .eq('category',
              mainCategory.name); // Utiliser mainCategory.name pour la requête

      final List<Map<String, dynamic>> servicesToDeleteData =
          List<Map<String, dynamic>>.from(servicesToDeleteResponse);
      List<String> serviceImagePathsToDelete = [];

      for (var serviceData in servicesToDeleteData) {
        if (serviceData['image_placeholder'] != null &&
            (serviceData['image_placeholder'] as String).isNotEmpty) {
          serviceImagePathsToDelete
              .add(serviceData['image_placeholder'] as String);
        }
      }

      // Supprimer les services de la base de données
      await _supabase
          .from('haircut_services')
          .delete()
          .eq('sub_category', subCategoryName)
          .eq('category',
              mainCategory.name); // Utiliser mainCategory.name pour la requête

      // Supprimer les images des services du bucket 'service.images'
      if (serviceImagePathsToDelete.isNotEmpty) {
        final result = await _supabase.storage
            .from('service.images')
            .remove(serviceImagePathsToDelete);
        // Vous pouvez vérifier result pour les erreurs de suppression d'images si nécessaire
        print('Résultat suppression images services: $result');
      }

      // Note: La suppression de 'image_placeholder_sous_category' est plus complexe
      // car elle est partagée et sa logique de suppression unique n'est pas définie ici.
      // Pour l'instant, nous ne supprimons que les images directes des services.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Sous-catégorie "$subCategoryName" (${mainCategory.name}) et ses services supprimés.'),
              backgroundColor: Colors.green),
        );
        _fetchServices(); // Recharger la liste
      }
    } catch (e) {
      if (mounted) {
        print("Erreur suppression sous-catégorie et services: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de la suppression: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supprimer Sous-Catégorie'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 8.0),
                      child: ToggleButtons(
                        borderColor: Theme.of(context).colorScheme.outline,
                        selectedBorderColor:
                            Theme.of(context).colorScheme.primary,
                        selectedColor: Theme.of(context).colorScheme.onPrimary,
                        fillColor: Theme.of(context).colorScheme.primary,
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8.0),
                        isSelected: _displayCategories
                            .map(
                                (category) => _selectedMainCategory == category)
                            .toList(),
                        onPressed: (int index) {
                          setState(() {
                            _selectedMainCategory = _displayCategories[index];
                          });
                        },
                        children: _displayCategories.map((category) {
                          return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(category.name[0].toUpperCase() +
                                  category.name.substring(1)));
                        }).toList(),
                      ),
                    ),
                    Expanded(
                      child: _buildSubCategorySelectionGrid(),
                    ),
                  ],
                ),
    );
  }
}
