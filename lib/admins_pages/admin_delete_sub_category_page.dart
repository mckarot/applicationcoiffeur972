import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:soifapp/models/haircut_service.dart';

class AdminDeleteSubCategoryPage extends StatefulWidget {
  const AdminDeleteSubCategoryPage({super.key});

  @override
  State<AdminDeleteSubCategoryPage> createState() =>
      _AdminDeleteSubCategoryPageState();
}

class _AdminDeleteSubCategoryPageState
    extends State<AdminDeleteSubCategoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
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
      final servicesSnapshot = await _firestore
          .collection('haircut_services')
          .orderBy('name')
          .get();

      if (mounted) {
        setState(() {
          _services = servicesSnapshot.docs
              .map((doc) => HaircutService.fromFirestore(doc))
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
      // L'URL complète est maintenant stockée directement dans le champ
      final imageUrl = subCategoryImagePath;
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
              'Voulez-vous vraiment supprimer la sous-catégorie "$subCategoryName" (${mainCategory.toJson()}) et TOUS les services qu\'elle contient ? Cette action est irréversible.'),
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
      // 1. Trouver tous les services dans la sous-catégorie à supprimer
      final servicesSnapshot = await _firestore
 .collection('haircut_services')
          .where('sub_category', isEqualTo: subCategoryName)
          .where('category', isEqualTo: mainCategory.toJson())
          .get();

      if (servicesSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun service trouvé à supprimer.')),
          );
        }
        return;
      }

      final List<String> serviceImageUrlsToDelete = [];
      for (final doc in servicesSnapshot.docs) {
        final data = doc.data();
        if (data['image_placeholder'] != null &&
            (data['image_placeholder'] as String).isNotEmpty) {
          serviceImageUrlsToDelete.add(data['image_placeholder'] as String);
        }
      }

      // 2. Supprimer les documents de Firestore en une seule opération (batch)
      final batch = _firestore.batch();
      for (final doc in servicesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // 3. Supprimer les images de Firebase Storage
      for (final imageUrl in serviceImageUrlsToDelete) {
        try {
          if (imageUrl.contains('firebasestorage.googleapis.com')) {
            await _storage.refFromURL(imageUrl).delete();
          }
        } catch (e) {
          print('Erreur lors de la suppression de l\'image $imageUrl: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Sous-catégorie "$subCategoryName" (${mainCategory.toJson()}) et ses services supprimés.'),
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
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                category.toJson()[0].toUpperCase() +
                                    category.toJson().substring(1),
                                style: const TextStyle(fontSize: 12),
                              ));
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
