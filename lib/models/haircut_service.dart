import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceCategory { homme, femme, enfant, mixte, undefined }

// Helper pour parser la catégorie depuis une chaîne
ServiceCategory serviceCategoryFromString(String categoryString) {
  switch (categoryString.toLowerCase()) {
    case 'homme':
      return ServiceCategory.homme;
    case 'femme':
      return ServiceCategory.femme;
    case 'enfant':
      return ServiceCategory.enfant;
    case 'mixte':
      return ServiceCategory.mixte;
    default:
      // Il est bon de loguer la valeur inconnue pour faciliter le débogage.
      print("Avertissement: Catégorie de service inconnue reçue: '$categoryString'. Utilisation de 'undefined'.");
      // Retourner une valeur par défaut au lieu de lancer une erreur pour plus de robustesse
      return ServiceCategory.undefined;
  }
}

// Extension pour ajouter la méthode toJson à ServiceCategory
extension ServiceCategoryExtension on ServiceCategory {
  /// Convertit l'enum ServiceCategory en sa représentation String (ex: "femme").
  String toJson() => name;
}

class HaircutService {
  final String id;
  final String name;
  final Duration duration;
  final double price;
  final String subCategory; // e.g., "Coupes", "Couleur", "Barbe"
  final ServiceCategory category;
  final String
      imagePlaceholder; // Utilisé pour une couleur ou icône de placeholder
  final String? imagePlaceholderSousCategory; // Nouveau champ

  HaircutService({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
    required this.subCategory,
    required this.category,
    required this.imagePlaceholder,
    this.imagePlaceholderSousCategory, // Ajouté ici
  });

  // Factory pour créer une instance depuis un document Firestore
  factory HaircutService.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HaircutService(
      id: doc.id,
      name: data['name'] as String,
      duration: Duration(minutes: data['duration_minutes'] as int),
      price: (data['price'] as num).toDouble(),
      subCategory: (data['sub_category'] as String).isNotEmpty
          ? '${(data['sub_category'] as String)[0].toUpperCase()}${(data['sub_category'] as String).substring(1).toLowerCase()}'
          : '',
      category: serviceCategoryFromString(data['category'] as String? ?? 'undefined'),
      imagePlaceholder: data['image_placeholder'] as String? ?? '',
      imagePlaceholderSousCategory: data['image_placeholder_sous_category'] as String?,
    );
  }

  // Méthode pour convertir l'instance en Map pour l'écriture dans Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'duration_minutes': duration.inMinutes,
      'price': price,
      'sub_category': subCategory,
      'category': category.toJson(),
      'image_placeholder': imagePlaceholder,
      'image_placeholder_sous_category': imagePlaceholderSousCategory,
    };
  }
}
