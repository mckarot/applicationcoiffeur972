// lib/models/sub_category_model.dart
import 'package:soifapp/models/haircut_service.dart'; // Pour ServiceCategory

class SubCategory {
  final String id;
  final String name;
  final ServiceCategory mainCategory;
  final String? imagePath; // Chemin vers l'image dans Supabase Storage
  final DateTime createdAt;

  SubCategory({
    required this.id,
    required this.name,
    required this.mainCategory,
    this.imagePath,
    required this.createdAt,
  });

  factory SubCategory.fromSupabase(Map<String, dynamic> data) {
    return SubCategory(
      id: data['id'] as String,
      name: data['name'] as String,
      mainCategory: serviceCategoryFromString(data['main_category'] as String),
      imagePath: data['image_path'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'main_category': mainCategory.toJson(),
      'image_path': imagePath,
      // created_at est géré par la base de données
    };
  }
}
