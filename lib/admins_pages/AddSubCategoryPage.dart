// /home/linux/StudioProjects/coifapp/soifapp/lib/admins_pages/add_sub_category_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soifapp/models/haircut_service.dart'; // Pour ServiceCategory
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AddSubCategoryPage extends StatefulWidget {
  const AddSubCategoryPage({super.key});

  @override
  State<AddSubCategoryPage> createState() => _AddSubCategoryPageState();
}

class _AddSubCategoryPageState extends State<AddSubCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  final List<String> _mainCategories =
      ServiceCategory.values.map((e) => e.toJson()).toList();
  String? _selectedMainCategory;
  File? _selectedImageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _addSubCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedMainCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner une catégorie principale.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? imagePathForDb;
    final String subCategoryId = _uuid.v4();

    try {
      if (_selectedImageFile != null) {
        final String fileExtension =
            _selectedImageFile!.path.split('.').last.toLowerCase();
        final String fileName = '$subCategoryId.$fileExtension';
        // Utilisation du nom de bucket corrigé
        imagePathForDb = 'public/$fileName';

        await _supabase.storage
            .from('sub.category.images') // NOM DU BUCKET CORRIGÉ
            .upload(imagePathForDb, _selectedImageFile!);
      }

      final subCategoryData = {
        'id': subCategoryId,
        'name': _nameController.text.trim(),
        'main_category': _selectedMainCategory!,
        'image_path': imagePathForDb,
      };

      await _supabase.from('sub_categories').insert(subCategoryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sous-catégorie ajoutée avec succès!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Retourne true pour indiquer un succès
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter une Sous-Catégorie"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Nom de la Sous-Catégorie*',
                    border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer le nom de la sous-catégorie.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMainCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie Principale*',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Sélectionnez une catégorie principale'),
                items: _mainCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child:
                        Text(category[0].toUpperCase() + category.substring(1)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMainCategory = newValue;
                  });
                },
                validator: (value) => value == null
                    ? 'Veuillez sélectionner une catégorie.'
                    : null,
              ),
              const SizedBox(height: 16),
              Text("Image de la sous-catégorie (optionnel) :",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    if (_selectedImageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            _selectedImageFile!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image_search_outlined),
                      label: Text(_selectedImageFile == null
                          ? 'Choisir une image'
                          : 'Changer l\'image'),
                      onPressed: _pickImage,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Ajouter la Sous-Catégorie'),
                      onPressed: _addSubCategory,
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
