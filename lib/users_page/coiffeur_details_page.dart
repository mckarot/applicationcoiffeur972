import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:soifapp/users_page/booking_page.dart'; // Pour le modèle Coiffeur

class CoiffeurDetailsPage extends StatelessWidget {
  final Coiffeur coiffeur;

  const CoiffeurDetailsPage({super.key, required this.coiffeur});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Utilisation d'un SliverAppBar pour un effet de défilement moderne
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            floating: false,
            stretch: true,
            backgroundColor: colorScheme.surfaceContainerHighest,
            // Ajout d'un bouton retour personnalisé pour la visibilité
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: BackButton(color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                coiffeur.name,
                style: TextStyle(
                  color: Colors.white, // Texte en blanc pour le contraste
                  fontWeight: FontWeight.bold,
                  shadows: [
                    // Ajout de l'ombre pour la lisibilité
                    const Shadow(
                      blurRadius: 8.0,
                      color: Colors.black54,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              background: Hero(
                tag: 'coiffeur-photo-${coiffeur.id}',
                child: coiffeur.photoUrl != null && coiffeur.photoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: coiffeur.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: coiffeur.color.withOpacity(0.5),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: coiffeur.color,
                          child: Icon(coiffeur.icon,
                              size: 80, color: Colors.white),
                        ),
                      )
                    : Container(
                        color: coiffeur.color,
                        child:
                            Icon(coiffeur.icon, size: 80, color: Colors.white),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Spécialités
                  if (coiffeur.specialites != null &&
                      coiffeur.specialites!.isNotEmpty)
                    _buildSectionCard(
                      context: context,
                      icon: Icons.auto_awesome_outlined,
                      title: 'Spécialités',
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: coiffeur.specialites!
                            .map((spec) => Chip(
                                  label: Text(spec),
                                  backgroundColor:
                                      colorScheme.secondaryContainer,
                                  labelStyle: TextStyle(
                                      color: colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w500),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ))
                            .toList(),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  // Section Bio
                  if (coiffeur.descriptionBio != null &&
                      coiffeur.descriptionBio!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context: context,
                      icon: Icons.info_outline_rounded,
                      title: 'À propos',
                      child: Text(
                        coiffeur.descriptionBio!,
                        style:
                            theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  ],
                  const SizedBox(height: 80), // Espace pour le bouton flottant
                ],
              ),
            ),
          ),
        ],
      ),
      // Bouton d'action flottant en bas
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Choisir ce coiffeur'),
            onPressed: () {
              Navigator.pop(context, coiffeur.id);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ).animate().slideY(begin: 2, delay: 400.ms, curve: Curves.easeOut),
        ),
      ),
    );
  }

  // Widget réutilisable pour créer une section dans une carte
  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}