import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soifapp/admins_pages/admin_edit_sub_category_page.dart';
import 'package:soifapp/models/haircut_service.dart';
import 'package:uuid/uuid.dart';

class AdminEditServicePage extends StatefulWidget {
  const AdminEditServicePage({super.key});

  @override
  State<AdminEditServicePage> createState() => _AdminEditServicePageState();
}

class _AdminEditServicePageState extends State<AdminEditServicePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<HaircutService> _services = [];
  List<SubCategory> _subCategories = [];
  bool _isLoading = true;
  String? _errorMessage;

  ServiceCategory _selectedMainCategory = ServiceCategory.femme;
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
    _fetchData();
  }

  Future<void> _fetchData() async {
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
      final subCategoriesSnapshot =
          await _firestore.collection('sub_categories').get();

      if (mounted) {
        setState(() {
          _services = servicesSnapshot.docs
              .map((doc) => HaircutService.fromFirestore(doc))
              .toList();
          _subCategories = subCategoriesSnapshot.docs
              .map((doc) => SubCategory.fromFirestore(doc))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Erreur fetchServices (admin edit): $e');
        setState(() {
          _errorMessage = "Impossible de charger les services.";
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToEditForm(HaircutService service) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => _EditServiceFormPage(service: service),
      ),
    ).then((wasUpdated) {
      if (wasUpdated == true) {
        _fetchData();
      }
    });
  }

  Widget _buildServiceImage(HaircutService service, BuildContext context) {
    if (service.imagePlaceholder.isNotEmpty) {
      final imageUrl = service.imagePlaceholder;
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
          return _buildDefaultServiceIcon(service, context);
        },
      );
    }
    return _buildDefaultServiceIcon(service, context);
  }

  Widget _buildDefaultServiceIcon(
      HaircutService service, BuildContext context) {
    IconData iconData;
    Color baseColor;
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
      case ServiceCategory.undefined:
        iconData = Icons.help_outline;
        baseColor = theme.brightness == Brightness.light
            ? Colors.grey[400]!
            : Colors.grey[600]!;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.20),
      ),
      child: Center(child: Icon(iconData, color: baseColor, size: 50)),
    );
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
          setState(() {
            _selectedSubCategoryName = subCategory.name;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: imageWidget,
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
      itemCount: filteredSubCategories.length,
      itemBuilder: (context, index) {
        final subCategory = filteredSubCategories[index];
        return _buildSubCategoryCard(subCategory);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSubCategoryName ?? 'Modifier une Prestation'),
        leading: _selectedSubCategoryName != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  setState(() {
                    _selectedSubCategoryName = null;
                  });
                },
              )
            : null,
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
                            _selectedSubCategoryName = null;
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
                      child: _selectedSubCategoryName == null
                          ? _buildSubCategorySelectionGrid()
                          : _buildServiceListForEditing(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildServiceListForEditing() {
    final List<HaircutService> servicesToList = _services.where((service) {
      if (service.name.startsWith('[SOUS-CATÉGORIE]')) {
        return false;
      }

      bool subCategoryMatch = service.subCategory.trim().toLowerCase() ==
          _selectedSubCategoryName?.trim().toLowerCase();
      if (!subCategoryMatch) return false;
      bool categoryMatch = service.category == _selectedMainCategory;
      return categoryMatch;
    }).toList();

    if (servicesToList.isEmpty) {
      return const Center(
          child: Text('Aucune prestation pour cette sous-catégorie.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: GridView.builder(
        padding: const EdgeInsets.all(12.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 0.75,
        ),
        itemCount: servicesToList.length,
        itemBuilder: (context, index) {
          final service = servicesToList[index];
          return Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _navigateToEditForm(service),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildServiceImage(service, context),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black.withOpacity(0.6),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(service.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                            '${service.price.toStringAsFixed(2)} € - ${service.duration.inMinutes} min',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EditServiceFormPage extends StatefulWidget {
  final HaircutService service;

  const _EditServiceFormPage({required this.service});

  @override
  State<_EditServiceFormPage> createState() => _EditServiceFormPageState();
}

class _EditServiceFormPageState extends State<_EditServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _durationController;
  late TextEditingController _priceController;

  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _durationController = TextEditingController(
        text: widget.service.duration.inMinutes.toString());
    _priceController =
        TextEditingController(text: widget.service.price.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImageFile = File(pickedFile.path));
    }
  }

  Future<void> _updateService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? newImageUrl;
      if (_selectedImageFile != null) {
        if (widget.service.imagePlaceholder.isNotEmpty) {
          try {
            await _storage.refFromURL(widget.service.imagePlaceholder).delete();
          } catch (e) {
            print(
                "Avertissement: L'ancienne image n'a pas pu être supprimée: $e");
          }
        }

        final String fileExtension =
            _selectedImageFile!.path.split('.').last.toLowerCase();
        final String fileName = '${const Uuid().v4()}.$fileExtension';
        final Reference storageRef =
            _storage.ref().child('service_images/$fileName');

        await storageRef.putFile(_selectedImageFile!);
        newImageUrl = await storageRef.getDownloadURL();
      }

      final dataToUpdate = {
        'name': _nameController.text.trim(),
        'duration_minutes': int.parse(_durationController.text.trim()),
        'price': double.parse(_priceController.text.trim()),
        'updated_at': FieldValue.serverTimestamp(),
        if (newImageUrl != null) 'image_placeholder': newImageUrl,
      };

      await _firestore
          .collection('haircut_services')
          .doc(widget.service.id)
          .update(dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Prestation mise à jour avec succès !'),
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
        title: Text('Modifier "${widget.service.name}"'),
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
                    const InputDecoration(labelText: 'Nom de la prestation'),
                validator: (value) =>
                    value!.isEmpty ? 'Le nom ne peut pas être vide.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Durée (minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    int.tryParse(value!) == null ? 'Durée invalide.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Prix (€)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    double.tryParse(value!) == null ? 'Prix invalide.' : null,
              ),
              const SizedBox(height: 24),
              if (_selectedImageFile != null)
                Image.file(_selectedImageFile!, height: 150),
              ElevatedButton.icon(
                icon: const Icon(Icons.image_search),
                label: const Text('Changer l\'image'),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _updateService,
                      child: const Text('Enregistrer les modifications'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
