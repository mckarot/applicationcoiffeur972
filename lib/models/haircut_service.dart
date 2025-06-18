enum ServiceCategory { homme, femme, enfant, mixte }

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
      print(
          "Erreur: Chaîne de catégorie de service inconnue reçue: '$categoryString'");
      throw ArgumentError('Unknown service category: $categoryString');
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

  HaircutService({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
    required this.subCategory,
    required this.category,
    required this.imagePlaceholder,
  });

  factory HaircutService.fromSupabase(Map<String, dynamic> data) {
    return HaircutService(
      id: data['id'] as String,
      name: data['name'] as String,
      duration: Duration(minutes: data['duration_minutes'] as int),
      price: (data['price'] as num).toDouble(),
      subCategory: data['sub_category'] as String,
      category: serviceCategoryFromString(
          data['category'] as String), // Utilise la fonction publique
      imagePlaceholder: data['image_placeholder'] as String? ?? '',
    );
  }
}
