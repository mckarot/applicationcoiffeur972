enum ServiceCategory { homme, femme, enfant, mixte }

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
}
