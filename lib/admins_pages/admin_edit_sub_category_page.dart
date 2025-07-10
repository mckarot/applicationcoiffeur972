import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soifapp/models/haircut_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Page de sélection de la sous-catégorie à modifier.
class AdminEditSubCategoryPage extends StatefulWidget {
  const AdminEditSubCategoryPage({super.key});

  @override
  State<AdminEditSubCategoryPage> createState() =>
      _AdminEditSubCategoryPageState();
}

class _AdminEditSubCategoryPageState extends State<AdminEditSubCategoryPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<HaircutService> _services = []; // Pour en déduire les sous-catégories
  bool _isLoading = true;
  String? _errorMessage;

  // État pour la sélection de la catégorie
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
      final data =
          await _supabase.from('haircut_services').select().order('name');
      if (mounted) {
        setState(() {
          _services =
              data.map((item) => HaircutService.fromSupabase(item)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Erreur fetchServices (admin edit sub-category): $e');
        setState(() {
          _errorMessage = "Impossible de charger les catégories.";
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToEditForm(String name, String? imagePath) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => _EditSubCategoryFormPage(
            initialName: name, initialImagePath: imagePath),
      ),
    ).then((wasUpdated) {
      if (wasUpdated == true) {
        _fetchServices(); // Rafraîchir les données après une mise à jour
      }
    });
  }

  // --- Méthodes de construction de l'UI adaptées de admin_edit_service_page.dart ---

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

  Widget _buildSubCategoryCard(
      String subCategoryName, String? subCategoryImagePath) {
    Widget imageWidget;

    if (subCategoryImagePath != null && subCategoryImagePath.isNotEmpty) {
      try {
        final imageUrl = _supabase.storage
            .from('sub.category.images')
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
        onTap: () => _navigateToEditForm(subCategoryName, subCategoryImagePath),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
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
          child: Text("Aucune catégorie à modifier pour cette sélection."));
    }

    return RefreshIndicator(
      onRefresh: _fetchServices,
      child: GridView.builder(
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
              : _services.isEmpty
                  ? const Center(child: Text('Aucune catégorie à modifier.'))
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
                                  text = 'Mixte';
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
                          child: _buildSubCategorySelectionGrid(),
                        ),
                      ],
                    ),
    );
  }
}

/// Formulaire d'édition pour une sous-catégorie.
class _EditSubCategoryFormPage extends StatefulWidget {
  final String initialName;
  final String? initialImagePath;

  const _EditSubCategoryFormPage({
    required this.initialName,
    this.initialImagePath,
  });

  @override
  State<_EditSubCategoryFormPage> createState() =>
      _EditSubCategoryFormPageState();
}

class _EditSubCategoryFormPageState extends State<_EditSubCategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _selectedImageFile;
  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
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
    final bool nameChanged = newName != widget.initialName;
    final bool imageChanged = _selectedImageFile != null;

    try {
      String? newImagePath;
      if (imageChanged) {
        final sanitizedName =
            newName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-').toLowerCase();
        final fileExtension =
            _selectedImageFile!.path.split('.').last.toLowerCase();
        final String fileName = '$sanitizedName-subcategory.$fileExtension';
        newImagePath = 'public/$fileName';

        await _supabase.storage.from('sub.category.images').upload(
            newImagePath, _selectedImageFile!,
            fileOptions: const FileOptions(upsert: true));
      }

      final updates = <String, dynamic>{};
      if (nameChanged) {
        updates['sub_category'] = newName;
      }
      if (imageChanged && newImagePath != null) {
        updates['image_placeholder_sous_category'] = newImagePath;
      }

      if (updates.isNotEmpty) {
        // Mettre à jour tous les services réels de cette catégorie
        await _supabase
            .from('haircut_services')
            .update(updates)
            .eq('sub_category', widget.initialName);

        // Mettre à jour le service placeholder s'il existe
        if (nameChanged) {
          final placeholderUpdates = {
            'name': '[SOUS-CATÉGORIE] $newName',
            ...updates
          };
          await _supabase
              .from('haircut_services')
              .update(placeholderUpdates)
              .eq('name', '[SOUS-CATÉGORIE] ${widget.initialName}');
        }
      }

      // Supprimer l'ancienne image du storage si une nouvelle a été uploadée
      if (imageChanged &&
          widget.initialImagePath != null &&
          widget.initialImagePath!.isNotEmpty) {
        await _supabase.storage
            .from('sub.category.images')
            .remove([widget.initialImagePath!]);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Catégorie mise à jour avec succès !'),
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
        title: Text('Modifier "${widget.initialName}"'),
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
