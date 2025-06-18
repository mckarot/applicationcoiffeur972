import 'dart:io'; // Importer dart:io pour File
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Importer image_picker
import 'package:uuid/uuid.dart'; // Importer le package uuid
// Importer le modèle HaircutService pour l'enum ServiceCategory si vous souhaitez l'utiliser pour la validation
// import 'package:soifapp/models/haircut_service.dart';

class AddHaircutServicePage extends StatefulWidget {
  const AddHaircutServicePage({super.key});

  @override
  State<AddHaircutServicePage> createState() => _AddHaircutServicePageState();
}

class _AddHaircutServicePageState extends State<AddHaircutServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _subCategoryController = TextEditingController();
  // Les contrôleurs pour les placeholders d'image sont remplacés par la sélection de fichiers

  final List<String> _categories = ['homme', 'femme', 'enfant', 'mixte'];
  String? _selectedCategory; // Initialisé à null pour forcer un choix

  File? _selectedServiceImageFile;
  File? _selectedSubCategoryImageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  final Uuid _uuid = const Uuid(); // Instance de Uuid

  @override
  void initState() {
    super.initState();
    _idController.text = _uuid.v4(); // Générer un ID UUID v4 par défaut
    _fetchExistingSubCategories();
  }

  List<String> _existingSubCategories = [];
  bool _isLoadingSubCategories = true;
  String? _selectedSubCategoryInDropdown; // Pour le DropdownButtonFormField

  Future<void> _fetchExistingSubCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSubCategories = true;
    });
    try {
      final response =
          await _supabase.from('haircut_services').select('sub_category');

      if (!mounted) return;

      final Set<String> subCategoriesSet = {};
      for (var item in response) {
        final subCategory = item['sub_category'] as String?;
        if (subCategory != null && subCategory.trim().isNotEmpty) {
          subCategoriesSet.add(subCategory.trim());
        }
      }
      setState(() {
        _existingSubCategories = subCategoriesSet.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _isLoadingSubCategories = false;
      });
    } catch (e) {
      if (mounted) {
        print("Erreur lors de la récupération des sous-catégories: $e");
        setState(() {
          _isLoadingSubCategories =
              false; // Permet de continuer même en cas d'erreur
        });
      }
    }
  }

  Future<void> _addService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? serviceImagePathForDb;
    String? subCategoryImagePathForDb;
    final String serviceId = _idController.text.trim();

    try {
      // Upload de l'image du service si sélectionnée
      if (_selectedServiceImageFile != null) {
        final String fileExtension =
            _selectedServiceImageFile!.path.split('.').last.toLowerCase();
        final String fileName = '$serviceId-service.$fileExtension';
        // Assurez-vous que le bucket 'service.images' existe
        serviceImagePathForDb = 'public/$fileName';
        await _supabase.storage
            .from('service.images')
            .upload(serviceImagePathForDb, _selectedServiceImageFile!);
      }

      // Upload de l'image de la sous-catégorie si sélectionnée
      if (_selectedSubCategoryImageFile != null) {
        final String fileExtension =
            _selectedSubCategoryImageFile!.path.split('.').last.toLowerCase();
        // Utiliser un nom de fichier distinctif, par exemple avec un suffixe
        final String fileName = '$serviceId-subcategory.$fileExtension';
        subCategoryImagePathForDb = 'public/$fileName';
        await _supabase.storage
            .from(
                'sub.category.images') // Correction: Utilisation du bucket existant
            .upload(subCategoryImagePathForDb, _selectedSubCategoryImageFile!);
      }

      final serviceData = {
        'id': serviceId,
        'name': _nameController.text.trim(),
        'duration_minutes': int.parse(_durationController.text.trim()),
        'price': double.parse(_priceController.text.trim()),
        'sub_category': _subCategoryController.text.trim(),
        'category': _selectedCategory!,
        'image_placeholder':
            serviceImagePathForDb, // Chemin de l'image du service
        'image_placeholder_sous_category':
            subCategoryImagePathForDb, // Chemin de l'image de la sous-catégorie
      };

      await _supabase.from('haircut_services').insert(serviceData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Service ajouté avec succès!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Retourne true pour indiquer un succès
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

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _subCategoryController.dispose();
    // Les contrôleurs pour les placeholders d'image ne sont plus nécessaires
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un Service"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _idController,
                readOnly: true, // Important: ID généré et non modifiable
                decoration: const InputDecoration(
                  labelText: 'ID du Service (automatique)',
                  border: OutlineInputBorder(),
                ),
                // Pas de validateur nécessaire car généré et non modifiable
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Nom du Service*', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le nom du service.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                    labelText: 'Durée (minutes)*',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer la durée.';
                  }
                  if (int.tryParse(value.trim()) == null ||
                      int.parse(value.trim()) <= 0) {
                    return 'Veuillez entrer une durée valide (nombre entier > 0).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                    labelText: 'Prix (€)*', border: OutlineInputBorder()),
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
                decoration: const InputDecoration(
                  labelText: 'Catégorie*',
                  border: OutlineInputBorder(),
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
                  });
                },
                validator: (value) => value == null
                    ? 'Veuillez sélectionner une catégorie.'
                    : null,
              ),
              const SizedBox(height: 16),
              if (_isLoadingSubCategories)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSubCategoryInDropdown,
                      decoration: const InputDecoration(
                        labelText:
                            'Choisir une sous-catégorie existante (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text(
                          'Sélectionner pour remplir le champ ci-dessous'),
                      items: _existingSubCategories.map((String subCategory) {
                        return DropdownMenuItem<String>(
                          value: subCategory,
                          child: Text(subCategory),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSubCategoryInDropdown = newValue;
                          _subCategoryController.text = newValue ?? '';
                          // Valider à nouveau le formulaire si on veut que le validateur du TextFormField réagisse
                          // _formKey.currentState?.validate();
                        });
                      },
                      // Pas de validateur ici, car le champ Autocomplete est le champ principal
                    ),
                    const SizedBox(height: 16),
                    Autocomplete<String>(
                      // Clé pour forcer la reconstruction si _subCategoryController.text change de l'extérieur (par le dropdown)
                      // initialValue est important pour que le champ texte de Autocomplete reflète les changements
                      // venant du DropdownButtonFormField.
                      initialValue:
                          TextEditingValue(text: _subCategoryController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        // textEditingValue est la valeur actuelle du champ texte de Autocomplete
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return _existingSubCategories.where((String option) {
                          return option
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        // Appelé quand une suggestion de l'Autocomplete est sélectionnée.
                        // Le champ texte de l'Autocomplete est déjà mis à jour avec 'selection'.
                        setState(() {
                          _subCategoryController.text = selection;
                          _selectedSubCategoryInDropdown =
                              selection; // Synchroniser le dropdown
                        });
                        FocusScope.of(context).unfocus();
                      },
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController
                              fieldTextEditingController, // Contrôleur interne à Autocomplete
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted) {
                        // fieldTextEditingController est initialisé par `initialValue` de Autocomplete.
                        // Si _subCategoryController.text a été changé par le dropdown,
                        // fieldTextEditingController.text reflètera cela grâce à `initialValue`.

                        return TextFormField(
                          controller:
                              fieldTextEditingController, // Utiliser le contrôleur fourni par Autocomplete
                          focusNode: fieldFocusNode,
                          decoration: const InputDecoration(
                              labelText: 'Sous-catégorie*',
                              hintText: 'Saisir une nouvelle sous-catégorie',
                              border: OutlineInputBorder()),
                          validator: (value) {
                            // Ce validateur s'applique au _subCategoryController.text effectif
                            if (_subCategoryController.text.trim().isEmpty) {
                              return 'Veuillez entrer ou sélectionner une sous-catégorie.';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // Appelé quand l'utilisateur tape dans le champ Autocomplete.
                            // Mettre à jour notre contrôleur principal et synchroniser le dropdown.
                            setState(() {
                              _subCategoryController.text = value;
                              if (_existingSubCategories.contains(value)) {
                                _selectedSubCategoryInDropdown = value;
                              } else {
                                _selectedSubCategoryInDropdown = null;
                              }
                            });
                          },
                          onFieldSubmitted: (_) => onFieldSubmitted(),
                        );
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Text("Image du Service (optionnel) :",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    if (_selectedServiceImageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            _selectedServiceImageFile!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image_search_outlined),
                      label: Text(_selectedServiceImageFile == null
                          ? 'Choisir une image pour le service'
                          : 'Changer l\'image du service'),
                      onPressed: _pickImageForService,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text("Image pour la Sous-Catégorie (optionnel) :",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    if (_selectedSubCategoryImageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            _selectedSubCategoryImageFile!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image_search_outlined),
                      label: Text(_selectedSubCategoryImageFile == null
                          ? 'Choisir une image pour la sous-catégorie'
                          : 'Changer l\'image de la sous-catégorie'),
                      onPressed: _pickImageForSubCategory,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Ajouter le Service'),
                      onPressed: _addService,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
