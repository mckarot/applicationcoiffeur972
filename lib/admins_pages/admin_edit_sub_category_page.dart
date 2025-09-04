import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soifapp/models/haircut_service.dart';
import 'package:uuid/uuid.dart';

// Modèle simple pour représenter une sous-catégorie
class SubCategory {
  final String id;
  final String name;
  final String category;
  final String? imageUrl;

  SubCategory({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl,
  });

  factory SubCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubCategory(
      id: doc.id,
      name: data['name'] ?? 'Nom inconnu',
      category: data['category'] ?? 'Catégorie inconnue',
      imageUrl: data['image_url'] as String?,
    );
  }
}

/// Page de sélection de la sous-catégorie à modifier.
class AdminEditSubCategoryPage extends StatefulWidget {
  const AdminEditSubCategoryPage({super.key});

  @override
  State<AdminEditSubCategoryPage> createState() =>
      _AdminEditSubCategoryPageState();
}

class _AdminEditSubCategoryPageState extends State<AdminEditSubCategoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
        print('Erreur fetchSubCategories (admin edit): $e');
        setState(() {
          _errorMessage = "Impossible de charger les catégories.";
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToEditForm(SubCategory subCategory) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => _EditSubCategoryFormPage(subCategory: subCategory),
      ),
    ).then((wasUpdated) {
      if (wasUpdated == true) {
        _fetchSubCategories();
      }
    });
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
    if (name == null || name.isEmpty) {
      return theme.colorScheme.surfaceBright;
    }
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
          final color = _getDynamicColorForSubCategory(subCategory.name, context);
          return Container(
              color: color.withAlpha((255 * 0.15).round()),
              child: Icon(icon, color: color, size: 50));
        },
      );
    } else {
      final icon = _getDynamicIconForSubCategory(subCategory.name);
      final color = _getDynamicColorForSubCategory(subCategory.name, context);
      imageWidget = Container(
          color: color.withAlpha((255 * 0.15).round()),
          child: Icon(icon, color: color, size: 50));
    }
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToEditForm(subCategory),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageWidget,
                  Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black.withOpacity(0.6),
                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
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
          child: Text("Aucune catégorie à modifier pour cette sélection."));
    }

    return RefreshIndicator(
      onRefresh: _fetchSubCategories,
      child: GridView.builder(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier une Catégorie'),
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
                          });
                        },
                        children: _displayCategories.map((category) {
                          return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0),
                              child: Text(category.toJson()[0].toUpperCase() + category.toJson().substring(1)));
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

/// Formulaire d'édition pour une sous-catégorie.
class _EditSubCategoryFormPage extends StatefulWidget {
  final SubCategory subCategory;

  const _EditSubCategoryFormPage({required this.subCategory});

  @override
  State<_EditSubCategoryFormPage> createState() =>
      _EditSubCategoryFormPageState();
}

class _EditSubCategoryFormPageState extends State<_EditSubCategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _selectedImageFile;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subCategory.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImageFile = File(pickedFile.path));
    }
  }

  Future<void> _updateSubCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newName = _nameController.text.trim();
    final bool nameChanged = newName != widget.subCategory.name;
    final bool imageChanged = _selectedImageFile != null;

    try {
      String? newImageUrl;
      if (imageChanged) {
        final fileExtension =
            _selectedImageFile!.path.split('.').last.toLowerCase();
        final String fileName = '${const Uuid().v4()}.$fileExtension';
        final Reference storageRef =
            _storage.ref().child('sub_category_images/$fileName');
        await storageRef.putFile(_selectedImageFile!);
        newImageUrl = await storageRef.getDownloadURL();
      }

      final subCategoryDocRef =
          _firestore.collection('sub_categories').doc(widget.subCategory.id);

      final subCategoryUpdateData = <String, dynamic>{};
      if (nameChanged) subCategoryUpdateData['name'] = newName;
      if (imageChanged && newImageUrl != null) {
        subCategoryUpdateData['image_url'] = newImageUrl;
      }

      if (subCategoryUpdateData.isNotEmpty) {
        await subCategoryDocRef.update(subCategoryUpdateData);
      }

      final servicesUpdateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp()
      };
      if (nameChanged) servicesUpdateData['sub_category'] = newName;
      if (imageChanged && newImageUrl != null) {
        servicesUpdateData['image_placeholder_sous_category'] = newImageUrl;
      }

      if (servicesUpdateData.length > 1) {
        final servicesToUpdateSnapshot = await _firestore
            .collection('haircut_services')
            .where('sub_category', isEqualTo: widget.subCategory.name)
            .where('category', isEqualTo: widget.subCategory.category)
            .get();

        final batch = _firestore.batch();
        for (final doc in servicesToUpdateSnapshot.docs) {
          batch.update(doc.reference, servicesUpdateData);
        }
        await batch.commit();
      }

      if (imageChanged &&
          widget.subCategory.imageUrl != null &&
          widget.subCategory.imageUrl!.isNotEmpty) {
        try {
          await _storage.refFromURL(widget.subCategory.imageUrl!).delete();
        } catch (e) {
          print(
              "Avertissement: L'ancienne image de sous-catégorie n'a pas pu être supprimée: $e");
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sous-catégorie mise à jour avec succès !'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
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
        title: Text('Modifier "${widget.subCategory.name}"'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: 'Nom de la catégorie'),
                validator: (value) =>
                    value!.isEmpty ? 'Le nom ne peut pas être vide.' : null,
              ),
              const SizedBox(height: 24),
              if (_selectedImageFile != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Image.file(_selectedImageFile!,
                      height: 150, fit: BoxFit.cover),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.image_search),
                label: const Text('Changer l\'image de la catégorie'),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _updateSubCategory,
                      child: const Text('Enregistrer les modifications'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}