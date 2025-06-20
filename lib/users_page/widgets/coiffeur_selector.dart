import 'package:flutter/material.dart';
import 'package:soifapp/users_page/booking_page.dart'; // Pour la classe Coiffeur et les helpers

class CoiffeurSelector extends StatelessWidget {
  final List<Coiffeur> coiffeurs;
  final String? selectedCoiffeurId;
  final Function(String) onCoiffeurSelected;
  final bool isLoading;
  final String? error;

  const CoiffeurSelector({
    super.key,
    required this.coiffeurs,
    this.selectedCoiffeurId,
    required this.onCoiffeurSelected,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
          child: Text(error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)));
    }

    if (coiffeurs.isEmpty) {
      return const Center(
          child: Text('Aucun coiffeur disponible pour le moment.'));
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: coiffeurs.length,
        itemBuilder: (context, index) {
          final coiffeur = coiffeurs[index];
          final isSelected = selectedCoiffeurId == coiffeur.id;
          return GestureDetector(
            onTap: () => onCoiffeurSelected(coiffeur.id),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.5)
                          : Border.all(color: Colors.transparent, width: 2.5),
                    ),
                    child: coiffeur.photoUrl != null &&
                            coiffeur.photoUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage(coiffeur.photoUrl!),
                            backgroundColor: Colors.grey[200],
                            onBackgroundImageError: (exception, stackTrace) {
                              print(
                                  'Erreur de chargement d\'image pour ${coiffeur.name}: $exception');
                            },
                          )
                        : CircleAvatar(
                            radius: 35,
                            backgroundColor: coiffeur.color.withOpacity(0.8),
                            child: Icon(coiffeur.icon,
                                size: 30, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coiffeur.name,
                    style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
