import 'package:cloud_firestore/cloud_firestore.dart';

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
