import 'dart:io'; // Importer dart:io pour File
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:soifapp/widgets/logout_button.dart';
import 'package:image_picker/image_picker.dart'; // Importer image_picker
import 'package:uuid/uuid.dart'; // Importer le package uuid

/// Page principale pour la gestion des services, organisée en onglets.
/// Permet d'ajouter un service ou d'ajouter une nouvelle sous-catégorie.
class AddHaircutServicePage extends StatefulWidget {
  const AddHaircutServicePage({
    super.key,
  });

  @override
  State<AddHaircutServicePage> createState() => _AddHaircutServicePageState();
}

class _AddHaircutServicePageState extends State<AddHaircutServicePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State partagé entre les onglets
  Map<String, List<String>> _subCategoriesByCategory = {};
  bool _isLoadingSubCategories = true;

  // Getter pour fournir une liste plate pour la validation dans l'onglet des sous-catégories
  List<String> get _allSubCategories {
    return _subCategoriesByCategory.values
        .expand((list) => list)
        .toSet()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchExistingSubCategories();
  }

  Future<void> _fetchExistingSubCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSubCategories = true;
    });
    try {
      // NOUVELLE LOGIQUE: Récupérer depuis la collection 'sub_categories'
      final subCategoriesSnapshot =
          await _firestore.collection('sub_categories').get();

      if (!mounted) return;

      final Map<String, Set<String>> subCategoriesMap = {};
      for (var doc in subCategoriesSnapshot.docs) {
        final item = doc.data();
        final category = item['category'] as String?;
        final subCategoryName = item['name'] as String?;
        if (category != null &&
            category.trim().isNotEmpty &&
            subCategoryName != null &&
            subCategoryName.trim().isNotEmpty) {
          (subCategoriesMap[category.trim()] ??= {}).add(subCategoryName.trim());
        }
      }
      final Map<String, List<String>> finalMap = {};
      subCategoriesMap.forEach((key, value) {
        finalMap[key] = value.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
      setState(() {
        _subCategoriesByCategory = finalMap;
        _isLoadingSubCategories = false;
      });
    } catch (e) {
      if (mounted) {
        print("Erreur lors de la récupération des sous-catégories: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Erreur de chargement des sous-catégories: ${e.toString()}"),
          backgroundColor: Colors.red,
        ));
        setState(() {
          _isLoadingSubCategories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        appBar: AppBar(
          title: const Text("Gestion des Services"),
          elevation: 4.0,
          actions: const [LogoutButton()],
          bottom: TabBar(
            tabs: const [
              Tab(
                  icon: Icon(Icons.create_new_folder_outlined),
                  text: "Nouvelle Catégorie"),
              Tab(
                  icon: Icon(Icons.add_shopping_cart_outlined),
                  text: "Nouveau Service"),
            ],
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          ),
        ),
        body: TabBarView(
          children: [
            _AddCategoryView(
              existingSubCategories: _allSubCategories,
              onSubCategoryAdded: () {
                _fetchExistingSubCategories();
              },
            ),
            _AddServiceView(
              subCategoriesByCategory: _subCategoriesByCategory,
              isLoadingSubCategories: _isLoadingSubCategories,
              onServiceAdded: () {
                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Onglet pour ajouter un nouveau service.
class _AddServiceView extends StatefulWidget {
  final Map<String, List<String>> subCategoriesByCategory;
  final bool isLoadingSubCategories;
  final VoidCallback onServiceAdded;

  const _AddServiceView({
    required this.subCategoriesByCategory,
    required this.isLoadingSubCategories,
    required this.onServiceAdded,
  });

  @override
  State<_AddServiceView> createState() => _AddServiceViewState();
}

class _AddServiceViewState extends State<_AddServiceView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();

  final List<String> _categories = ['homme', 'femme', 'enfant', 'mixte'];
  String? _selectedCategory;
  String? _selectedSubCategory;
  List<String> _availableSubCategories = [];

  File? _selectedServiceImageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _addService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // NOUVELLE LOGIQUE: Récupérer l\'URL de l\'image depuis la collection 'sub_categories'
      String? subCategoryImageUrl;
      final subCategoryQuery = await _firestore
          .collection('sub_categories')
          .where('name', isEqualTo: _selectedSubCategory!)
          .where('category', isEqualTo: _selectedCategory!)
          .limit(1)
          .get();

      if (subCategoryQuery.docs.isNotEmpty) {
        subCategoryImageUrl =
            subCategoryQuery.docs.first.data()['image_url'] as String?;
      }

      // Upload de l\'image du service si sélectionnée
      String? serviceImageUrlForDb;
      if (_selectedServiceImageFile != null) {
        final String fileExtension =
            _selectedServiceImageFile!.path.split('.').last.toLowerCase();
        final String fileName = '${const Uuid().v4()}.$fileExtension';
        final ref = _storage.ref().child('service_images/$fileName');
        await ref.putFile(_selectedServiceImageFile!);
        serviceImageUrlForDb = await ref.getDownloadURL();
      }

      final serviceData = {
        'name': _nameController.text.trim(),
        'duration_minutes': int.parse(_durationController.text.trim()),
        'price': double.parse(_priceController.text.trim()),
        'sub_category': _selectedSubCategory!,
        'category': _selectedCategory!,
        'image_placeholder': serviceImageUrlForDb ?? '',
        'image_placeholder_sous_category': subCategoryImageUrl,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('haircut_services').add(serviceData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Service ajouté avec succès!'),
              backgroundColor: Colors.green),
        );
        widget.onServiceAdded();
      }
    } catch (e) {
      if (mounted) {
        print("Erreur lors de l'ajout du service: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Erreur lors de l'ajout du service: ${e.toString()}"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImageForService() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _selectedServiceImageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 8.0,
          shape: 
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    "Ajouter un nouveau service",
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: _buildInputDecoration(
                        context: context,
                        label: 'Nom du Service*', 
                        prefixIcon: Icons.cut),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Veuillez entrer le nom du service.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: _buildInputDecoration(
                      context: context,
                      label: 'Durée (minutes) *',
                      hint: 'Durée minimale 30 min',
                      prefixIcon: Icons.timer_outlined,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer la durée.';
                      }
                      final duration = int.tryParse(value.trim());
                      if (duration == null) {
                        return 'Veuillez entrer un nombre entier valide.';
                      }
                      if (duration < 30) {
                        return 'La durée minimale doit être de 30 minutes.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: _buildInputDecoration(
                        context: context,
                        label: 'Prix (€)*',
                        prefixIcon: Icons.euro_symbol),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer le prix.';
                      }
                      if (double.tryParse(value.trim()) == null ||
                          double.parse(value.trim()) < 0) {
                        return 'Veuillez entrer un prix valide (nombre >= 0).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: _buildInputDecoration(
                      context: context,
                      label: 'Catégorie*', 
                      prefixIcon: Icons.category_outlined,
                    ),
                    hint: const Text('Sélectionnez une catégorie'),
                    isExpanded: true,
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category[0].toUpperCase() + category.substring(1),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                        _selectedSubCategory = null;
                        if (newValue != null &&
                            widget.subCategoriesByCategory.containsKey(newValue)) {
                          _availableSubCategories =
                              widget.subCategoriesByCategory[newValue]!;
                        } else {
                          _availableSubCategories = [];
                        }
                      });
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Veuillez sélectionner une catégorie.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (widget.isLoadingSubCategories)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubCategory,
                      decoration: _buildInputDecoration(
                        context: context,
                        label: 'Sous-catégorie*', 
                        prefixIcon: Icons.list_alt,
                      ),
                      hint: Text(_selectedCategory == null
                          ? 'Choisissez d\'abord une catégorie'
                          : 'Sélectionnez une sous-catégorie'),
                      items:
                          _availableSubCategories.map((String subCategory) {
                        return DropdownMenuItem<String>(
                          value: subCategory,
                          child: Text(
                            subCategory,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      isExpanded: true,
                      onChanged: (_selectedCategory == null ||
                              _availableSubCategories.isEmpty)
                          ? null
                          : (String? newValue) =>
                              setState(() => _selectedSubCategory = newValue),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Veuillez sélectionner une sous-catégorie.'
                          : null,
                    ),
                  const SizedBox(height: 24),
                  Text("Image du Service (optionnel) :",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildImagePicker(
                    context: context,
                    selectedFile: _selectedServiceImageFile,
                    onPressed: _pickImageForService,
                    buttonText: 'Choisir une image pour le service',
                    changeButtonText: 'Changer l\'image du service',
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Ajouter le Service'),
                          onPressed: _addService,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            textStyle: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            elevation: 5.0,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Onglet pour ajouter une nouvelle sous-catégorie.
class _AddCategoryView extends StatefulWidget {
  final List<String> existingSubCategories;
  final VoidCallback onSubCategoryAdded;

  const _AddCategoryView({
    required this.onSubCategoryAdded,
    required this.existingSubCategories,
  });

  @override
  State<_AddCategoryView> createState() => _AddCategoryViewState();
}

class _AddCategoryViewState extends State<_AddCategoryView> {
  final _formKey = GlobalKey<FormState>();
  final _subCategoryNameController = TextEditingController();
  File? _selectedSubCategoryImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final List<String> _categories = ['homme', 'femme', 'enfant', 'mixte'];
  String? _selectedCategoryForSubCategory;

  @override
  void dispose() {
    _subCategoryNameController.dispose();
    super.dispose();
  }

  Future<void> _addSubCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedSubCategoryImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Veuillez sélectionner une image pour la sous-catégorie.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final String newName = _subCategoryNameController.text.trim();

    try {
      // NOUVELLE LOGIQUE: Créer un document dans la collection 'sub_categories'
      final String fileExtension =
          _selectedSubCategoryImageFile!.path.split('.').last.toLowerCase();
      final String fileName = '${const Uuid().v4()}.$fileExtension';
      final ref = _storage.ref().child('sub_category_images/$fileName');
      await ref.putFile(_selectedSubCategoryImageFile!);
      final subCategoryImageUrlForDb = await ref.getDownloadURL();

      final subCategoryData = {
        'name': newName,
        'category': _selectedCategoryForSubCategory!,
        'image_url': subCategoryImageUrlForDb,
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('sub_categories').add(subCategoryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Catégorie ajoutée avec succès!'),
              backgroundColor: Colors.green),
        );
        _subCategoryNameController.clear();
        setState(() {
          _selectedSubCategoryImageFile = null;
          _selectedCategoryForSubCategory = null;
        });
        widget.onSubCategoryAdded();
      }
    } catch (e) {
      if (mounted) {
        print("Erreur lors de l'ajout de la catégorie: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Erreur lors de l'ajout de la catégorie: ${e.toString()}"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImageForSubCategory() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _selectedSubCategoryImageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 8.0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Créer une nouvelle catégorie",
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Cette catégorie sera disponible dans le formulaire de création de service.",
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryForSubCategory,
                    decoration: _buildInputDecoration(
                      context: context,
                      label: 'Associer à la catégorie*', 
                      prefixIcon: Icons.category_outlined,
                    ),
                    hint: const Text('Sélectionnez une catégorie'),
                    isExpanded: true,
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category[0].toUpperCase() + category.substring(1),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategoryForSubCategory = newValue;
                      });
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Veuillez sélectionner une catégorie.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _subCategoryNameController,
                    decoration: _buildInputDecoration(
                      context: context,
                      label: 'Nom de la nouvelle catégorie*', 
                      prefixIcon: Icons.create_new_folder_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer le nom de la catégorie.';
                      }
                      if (widget.existingSubCategories.any((c) =>
                          c.toLowerCase() == value.trim().toLowerCase())) {
                        return 'Cette catégorie existe déjà.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text("Image pour la Catégorie* :",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildImagePicker(
                    context: context,
                    selectedFile: _selectedSubCategoryImageFile,
                    onPressed: _pickImageForSubCategory,
 buttonText: 'Choisir une image pour la catégorie',
 changeButtonText: 'Changer l\'image de la catégorie',
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Ajouter la Catégorie'),
                          onPressed: _addSubCategory,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            textStyle: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            elevation: 5.0,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Widgets et Méthodes Utilitaires ---

InputDecoration _buildInputDecoration ({
  required BuildContext context,
  required String label,
  String? hint,
  IconData? prefixIcon,
}) {
  final theme = Theme.of(context);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: theme.colorScheme.primary)
        : null,
    filled: true,
    fillColor: theme.colorScheme.surface,
    contentPadding:
        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none, // No border, relies on fillColor
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
    ),
  );
}

Widget _buildImagePicker ({
  required BuildContext context,
  required File? selectedFile,
  required VoidCallback onPressed,
  required String buttonText,
  required String changeButtonText,
}) {
  final theme = Theme.of(context);
  return Center(
    child: Column(
      children: [
        if (selectedFile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                selectedFile,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ElevatedButton.icon(
          icon: const Icon(Icons.image_search_outlined),
          label: Text(selectedFile == null ? buttonText : changeButtonText),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
          ),
        ),
      ],
    ),
  );
}
