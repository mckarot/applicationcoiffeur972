import 'dart:io'; // Importer dart:io pour File
import 'package:flutter/material.dart';
import 'package:soifapp/widgets/logout_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final SupabaseClient _supabase = Supabase.instance.client;

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
      // Récupérer à la fois la catégorie et la sous-catégorie
      final response = await _supabase
          .from('haircut_services')
          .select('category, sub_category');

      if (!mounted) return;

      // Utiliser une map pour grouper les sous-catégories par catégorie
      final Map<String, Set<String>> subCategoriesMap = {};
      for (var item in response) {
        final category = item['category'] as String?;
        final subCategory = item['sub_category'] as String?;
        if (category != null &&
            category.trim().isNotEmpty &&
            subCategory != null &&
            subCategory.trim().isNotEmpty) {
          // Initialiser l'ensemble si la catégorie est nouvelle
          (subCategoriesMap[category.trim()] ??= {}).add(subCategory.trim());
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
          _isLoadingSubCategories =
              false; // Permet de continuer même en cas d'erreur
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Ajouter Service / Catégorie"),
          actions: const [LogoutButton()],
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.add), text: "Service"),
              Tab(
                  icon: Icon(Icons.create_new_folder_outlined),
                  text: "Sous-Catégorie"),
            ],
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          ),
        ),
        body: TabBarView(
          children: [
            _AddServiceView(
              subCategoriesByCategory: _subCategoriesByCategory,
              isLoadingSubCategories: _isLoadingSubCategories,
              onServiceAdded: () {
                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
            _AddSubCategoryView(
              existingSubCategories: _allSubCategories,
              onSubCategoryAdded: () {
                // Rafraîchit la liste des sous-catégories pour le premier onglet
                _fetchExistingSubCategories();
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
  final _idController = TextEditingController();
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
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _idController.text = _uuid.v4();
  }

  @override
  void dispose() {
    _idController.dispose();
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

    String? serviceImagePathForDb;
    final String serviceId = _idController.text.trim();

    try {
      // Upload de l'image du service si sélectionnée
      if (_selectedServiceImageFile != null) {
        final String fileExtension =
            _selectedServiceImageFile!.path.split('.').last.toLowerCase();
        final String fileName = '$serviceId-service.$fileExtension';
        serviceImagePathForDb = 'public/$fileName';
        await _supabase.storage
            .from('service.images')
            .upload(serviceImagePathForDb, _selectedServiceImageFile!);
      }

      final serviceData = {
        'id': serviceId,
        'name': _nameController.text.trim(),
        'duration_minutes': int.parse(_durationController.text.trim()),
        'price': double.parse(_priceController.text.trim()),
        'sub_category': _selectedSubCategory!,
        'category': _selectedCategory!,
        'image_placeholder': serviceImagePathForDb,
        // L'image de la sous-catégorie est gérée via l'onglet "Ajouter une Sous-Catégorie"
        'image_placeholder_sous_category': null,
      };

      await _supabase.from('haircut_services').insert(serviceData);

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
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _idController,
                readOnly: true,
                decoration: _buildInputDecoration(
                    context: context, label: 'ID du Service (automatique)'),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
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
                value: _selectedCategory,
                decoration: _buildInputDecoration(
                  context: context,
                  label: 'Catégorie*',
                  prefixIcon: Icons.category_outlined,
                ),
                hint: const Text('Sélectionnez une catégorie'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child:
                        Text(category[0].toUpperCase() + category.substring(1)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                    // Réinitialiser la sous-catégorie lorsque la catégorie change
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
                  value: _selectedSubCategory,
                  decoration: _buildInputDecoration(
                    context: context,
                    label: 'Sous-catégorie*',
                    prefixIcon: Icons.list_alt,
                  ),
                  hint: Text(_selectedCategory == null
                      ? 'Choisissez d\'abord une catégorie'
                      : 'Sélectionnez une sous-catégorie'),
                  items: _availableSubCategories.map((String subCategory) {
                    return DropdownMenuItem<String>(
                      value: subCategory,
                      child: Text(subCategory),
                    );
                  }).toList(),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ));
  }
}

/// Onglet pour ajouter une nouvelle sous-catégorie.
class _AddSubCategoryView extends StatefulWidget {
  final List<String> existingSubCategories;
  final VoidCallback onSubCategoryAdded;

  const _AddSubCategoryView({
    required this.onSubCategoryAdded,
    required this.existingSubCategories,
  });

  @override
  State<_AddSubCategoryView> createState() => _AddSubCategoryViewState();
}

class _AddSubCategoryViewState extends State<_AddSubCategoryView> {
  final _formKey = GlobalKey<FormState>();
  final _subCategoryNameController = TextEditingController();
  File? _selectedSubCategoryImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

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
      // 1. Upload de l'image de la sous-catégorie
      final String fileExtension =
          _selectedSubCategoryImageFile!.path.split('.').last.toLowerCase();
      final sanitizedName =
          newName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-').toLowerCase();
      final String fileName = '$sanitizedName-subcategory.$fileExtension';
      final String subCategoryImagePathForDb = 'public/$fileName';

      await _supabase.storage
          .from('sub.category.images')
          .upload(subCategoryImagePathForDb, _selectedSubCategoryImageFile!);

      // 2. Création d'un service "placeholder" pour stocker la sous-catégorie
      // C'est une solution de contournement due à la structure de la BDD actuelle.
      final placeholderServiceData = {
        'id': _uuid.v4(),
        'name': '[SOUS-CATÉGORIE] $newName',
        'duration_minutes': 0,
        'price': 0.0,
        'sub_category': newName,
        'category': 'mixte', // Catégorie par défaut
        'image_placeholder_sous_category': subCategoryImagePathForDb,
      };

      await _supabase.from('haircut_services').insert(placeholderServiceData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sous-catégorie ajoutée avec succès!'),
              backgroundColor: Colors.green),
        );
        _subCategoryNameController.clear();
        setState(() {
          _selectedSubCategoryImageFile = null;
        });
        widget
            .onSubCategoryAdded(); // Notifie le parent pour rafraîchir la liste
      }
    } catch (e) {
      if (mounted) {
        print("Erreur lors de l'ajout de la sous-catégorie: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Erreur lors de l'ajout de la sous-catégorie: ${e.toString()}"),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Créer une nouvelle sous-catégorie",
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Cela ajoutera l'option dans la liste déroulante du formulaire de service.",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _subCategoryNameController,
              decoration: _buildInputDecoration(
                context: context,
                label: 'Nom de la nouvelle sous-catégorie*',
                prefixIcon: Icons.create_new_folder_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer le nom de la sous-catégorie.';
                }
                if (widget.existingSubCategories.any(
                    (c) => c.toLowerCase() == value.trim().toLowerCase())) {
                  return 'Cette sous-catégorie existe déjà.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text("Image pour la Sous-Catégorie* :",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildImagePicker(
              context: context,
              selectedFile: _selectedSubCategoryImageFile,
              onPressed: _pickImageForSubCategory,
              buttonText: 'Choisir une image pour la sous-catégorie',
              changeButtonText: 'Changer l\'image de la sous-catégorie',
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Ajouter la Sous-Catégorie'),
                    onPressed: _addSubCategory,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// --- Widgets et Méthodes Utilitaires ---

InputDecoration _buildInputDecoration({
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
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}

Widget _buildImagePicker({
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
