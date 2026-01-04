import 'package:flutter/material.dart';
import 'package:soifapp/admins_pages/add_haircut_service_page.dart';
import 'package:soifapp/admins_pages/admin_delete_sub_category_page.dart';
import 'package:soifapp/admins_pages/admin_edit_service_page.dart';
import 'package:soifapp/admins_pages/admin_edit_sub_category_page.dart';
import 'package:soifapp/admins_pages/admin_manage_services_page.dart';
import 'package:soifapp/admins_pages/admin_delete_coiffeur_page.dart';
import 'package:soifapp/admins_pages/sign_up_page.dart';
import 'package:soifapp/widgets/logout_button.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0, // Remove shadow for a flatter look
      color:
          theme.colorScheme.surfaceContainerHighest, // Subtle background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant
              .withOpacity(0.5), // Subtle border
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Increased padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 36, // Slightly smaller icon
                  color: iconColor ?? theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: const [LogoutButton()],
        elevation: 0,
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildActionCard(
                context: context,
                icon: Icons.person_add_alt_1_outlined,
                title: 'Créer Utilisateur',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()))),
            _buildActionCard(
                context: context,
                icon: Icons.person_remove_outlined,
                title: 'Supprimer Coiffeur',
                iconColor: Colors.red,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminDeleteCoiffeurPage()))),
            // --- Section Prestations ---
            _buildActionCard(
                context: context,
                icon: Icons.add_shopping_cart_outlined,
                title: 'Ajouter Prestation',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddHaircutServicePage()))),
            _buildActionCard(
                context: context,
                icon: Icons.edit_note_outlined,
                title: 'Modifier Prestation',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminEditServicePage()))),
            _buildActionCard(
                context: context,
                icon: Icons.list_alt_outlined,
                title: 'Supprimer Prestation',
                iconColor: Colors.orange[800],
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminManageServicesPage()))),
            // --- Section Catégories ---
            _buildActionCard(
                context: context,
                icon: Icons.edit_attributes_outlined,
                title: 'Modifier Catégorie',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminEditSubCategoryPage()))),
            _buildActionCard(
                context: context,
                icon: Icons.delete_sweep_outlined,
                title: 'Supprimer Catégories',
                iconColor: Colors.redAccent,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminDeleteSubCategoryPage()))),
          ],
        ),
      ),
    );
  }
}