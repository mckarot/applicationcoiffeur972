import 'package:flutter/material.dart';
import 'package:soifapp/users_page/booking_page.dart'; // Pour le modèle Coiffeur

class CoiffeurDetailsPage extends StatelessWidget {
  final Coiffeur coiffeur;

  const CoiffeurDetailsPage({super.key, required this.coiffeur});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(coiffeur.name),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo and Name
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: coiffeur.photoUrl != null &&
                                coiffeur.photoUrl!.isNotEmpty
                            ? Image.network(
                                coiffeur.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    CircleAvatar(
                                  backgroundColor: coiffeur.color,
                                  child: Icon(coiffeur.icon,
                                      size: 60, color: Colors.white),
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: coiffeur.color,
                                child: Icon(coiffeur.icon,
                                    size: 60, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      coiffeur.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Specialities
            if (coiffeur.specialites != null &&
                coiffeur.specialites!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Spécialités',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: coiffeur.specialites!
                      .map((spec) => Chip(
                            label: Text(spec),
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            labelStyle: TextStyle(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w500),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Bio
            if (coiffeur.descriptionBio != null &&
                coiffeur.descriptionBio!.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'À propos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  coiffeur.descriptionBio!,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Choisir ce coiffeur'),
            onPressed: () {
              // Retourne l'ID du coiffeur à la page précédente
              Navigator.pop(context, coiffeur.id);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
        ),
      ),
    );
  }
}
