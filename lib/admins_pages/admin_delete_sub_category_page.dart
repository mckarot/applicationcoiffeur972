import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:soifapp/admins_pages/admin_edit_sub_category_page.dart'; // Réutilisation du modèle SubCategory
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
  List<SubCategory> _subCategories = [];
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
    _fetchSubCategories();
  }

  Future<void> _fetchSubCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot =
          await _firestore.collection('sub_categories').get();
      if (mounted) {
        setState(() {
          _subCategories =
              snapshot.docs.map((doc) => SubCategory.fromFirestore(doc)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Erreur fetchSubCategories (admin delete): $e');
        setState(() {
          _errorMessage =
              'Impossible de charger les données pour les sous-catégories.';
          _isLoading = false;
        });
      }
    }
  }

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

  Widget _buildSubCategoryCard(SubCategory subCategory) {
    Widget imageWidget;

    if (subCategory.imageUrl != null && subCategory.imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        subCategory.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          final icon = _getDynamicIconForSubCategory(subCategory.name);
          final color =
              _getDynamicColorForSubCategory(subCategory.name, context);
          return Container(
              color: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 50));
        },
      );
    } else {
      final icon = _getDynamicIconForSubCategory(subCategory.name);
      final color = _getDynamicColorForSubCategory(subCategory.name, context);
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
          _confirmDeleteSubCategory(subCategory);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: imageWidget),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                subCategory.name,
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
    final filteredSubCategories = _subCategories.where((sc) {
      return sc.category == _selectedMainCategory.toJson();
    }).toList();

    if (filteredSubCategories.isEmpty) {
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
      itemCount: filteredSubCategories.length,
      itemBuilder: (context, index) {
        final subCategory = filteredSubCategories[index];
        return _buildSubCategoryCard(subCategory);
      },
    );
  }

  Future<void> _confirmDeleteSubCategory(SubCategory subCategory) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
              'Voulez-vous vraiment supprimer la sous-catégorie "${subCategory.name}" (${subCategory.category}) et TOUS les services qu\'elle contient ? Cette action est irréversible.'),
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
      await _deleteSubCategoryAndServices(subCategory);
    }
  }

  Future<void> _deleteSubCategoryAndServices(SubCategory subCategory) async {
    setState(() => _isLoading = true);
    try {
      final servicesSnapshot = await _firestore
          .collection('haircut_services')
          .where('sub_category', isEqualTo: subCategory.name)
          .where('category', isEqualTo: subCategory.category)
          .get();

      final List<String> serviceImageUrlsToDelete = [];
      for (final doc in servicesSnapshot.docs) {
        final data = doc.data();
        if (data['image_placeholder'] != null &&
            (data['image_placeholder'] as String).isNotEmpty) {
          serviceImageUrlsToDelete.add(data['image_placeholder'] as String);
        }
      }

      final batch = _firestore.batch();
      // Supprimer les services
      for (final doc in servicesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      // Supprimer la sous-catégorie elle-même
      batch.delete(_firestore.collection('sub_categories').doc(subCategory.id));
      await batch.commit();

      // Supprimer les images des services
      for (final imageUrl in serviceImageUrlsToDelete) {
        try {
          if (imageUrl.contains('firebasestorage.googleapis.com')) {
            await _storage.refFromURL(imageUrl).delete();
          }
        } catch (e) {
          print('Erreur lors de la suppression de l\'image de service $imageUrl: $e');
        }
      }
      // Supprimer l'image de la sous-catégorie
      if (subCategory.imageUrl != null && subCategory.imageUrl!.isNotEmpty) {
        try {
          await _storage.refFromURL(subCategory.imageUrl!).delete();
        } catch (e) {
          print('Erreur lors de la suppression de l\'image de sous-catégorie ${subCategory.imageUrl}: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Sous-catégorie "${subCategory.name}" et ses services supprimés.'),
              backgroundColor: Colors.green),
        );
        _fetchSubCategories();
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