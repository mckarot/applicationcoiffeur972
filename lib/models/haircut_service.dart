enum ServiceCategory { homme, femme, enfant, mixte }

// Helper pour parser la catégorie depuis une chaîne
ServiceCategory _parseServiceCategory(String categoryString) {
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
      throw ArgumentError('Unknown service category: $categoryString');
  }
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
      category: _parseServiceCategory(data['category'] as String),
      imagePlaceholder: data['image_placeholder'] as String? ?? '',
    );
  }
}
