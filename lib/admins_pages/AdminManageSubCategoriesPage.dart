// /home/linux/StudioProjects/coifapp/soifapp/lib/admins_pages/admin_manage_sub_categories_page.dart
import 'package:flutter/material.dart';
import 'package:soifapp/admins_pages/AddSubCategoryPage.dart';

import 'package:soifapp/models/SubCategory.dart';

import 'package:soifapp/models/haircut_service.dart'; // Pour ServiceCategory
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminManageSubCategoriesPage extends StatefulWidget {
  const AdminManageSubCategoriesPage({super.key});

  @override
  State<AdminManageSubCategoriesPage> createState() =>
      _AdminManageSubCategoriesPageState();
}

class _AdminManageSubCategoriesPageState
    extends State<AdminManageSubCategoriesPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<SubCategory> _subCategories = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      final List<Map<String, dynamic>> data =
          await _supabase.from('sub_categories').select().order('name');

      if (mounted) {
        setState(() {
          _subCategories =
              data.map((item) => SubCategory.fromSupabase(item)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Erreur fetchSubCategories (admin): $e');
        setState(() {
          _errorMessage = 'Impossible de charger les sous-catégories.';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSubCategoryImage(SubCategory subCategory, BuildContext context) {
    if (subCategory.imagePath != null && subCategory.imagePath!.isNotEmpty) {
      try {
        final imageUrl = _supabase.storage
            .from('sub.category.images') // NOM DU BUCKET CORRIGÉ
            .getPublicUrl(subCategory.imagePath!);
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
                        : null));
          },
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
            print('Erreur chargement image sous-catégorie (admin): $error');
            return _buildDefaultSubCategoryIcon(subCategory, context);
          },
        );
      } catch (e) {
        print("Erreur construction URL image sous-catégorie (admin): $e");
        return _buildDefaultSubCategoryIcon(subCategory, context);
      }
    }
    return _buildDefaultSubCategoryIcon(subCategory, context);
  }

  Widget _buildDefaultSubCategoryIcon(
      SubCategory subCategory, BuildContext context) {
    IconData iconData;
    Color baseColor;
    final theme = Theme.of(context);

    switch (subCategory.mainCategory) {
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
      default:
        iconData = Icons.category_outlined;
        baseColor = theme.brightness == Brightness.light
            ? Colors.purple[200]!
            : Colors.purple[700]!;
        break;
    }
    return Container(
      decoration: BoxDecoration(color: baseColor.withOpacity(0.20)),
      child: Center(child: Icon(iconData, color: baseColor, size: 50)),
    );
  }

  Future<void> _deleteSubCategory(
      String subCategoryId, String subCategoryName, String? imagePath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
              'Voulez-vous vraiment supprimer la sous-catégorie "$subCategoryName" ? Cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _supabase.from('sub_categories').delete().eq('id', subCategoryId);

        if (imagePath != null && imagePath.isNotEmpty) {
          try {
            await _supabase.storage
                .from('sub.category.images') // NOM DU BUCKET CORRIGÉ
                .remove([imagePath]);
          } catch (storageError) {
            print(
                "Erreur suppression image '$imagePath' du storage: $storageError");
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Sous-catégorie "$subCategoryName" supprimée.'),
                backgroundColor: Colors.green),
          );
          _fetchSubCategories();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur lors de la suppression: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les Sous-Catégories'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : _subCategories.isEmpty
                  ? const Center(child: Text('Aucune sous-catégorie à gérer.'))
                  : RefreshIndicator(
                      onRefresh: _fetchSubCategories,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.0,
                          mainAxisSpacing: 12.0,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _subCategories.length,
                        itemBuilder: (context, index) {
                          final subCategory = _subCategories[index];
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _buildSubCategoryImage(
                                      subCategory, context),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        subCategory.name,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        subCategory.mainCategory
                                            .toJson()
                                            .toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    icon: Icon(Icons.delete_forever_outlined,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        size: 26),
                                    tooltip: 'Supprimer cette sous-catégorie',
                                    onPressed: () => _deleteSubCategory(
                                        subCategory.id,
                                        subCategory.name,
                                        subCategory.imagePath),
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddSubCategoryPage()),
          );
          if (result == true && mounted) {
            _fetchSubCategories();
          }
        },
        label: const Text('Ajouter'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
