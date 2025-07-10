import 'package:flutter/material.dart';
import 'package:soifapp/admins_pages/manage_coiffeurs_page.dart'; // Importer la nouvelle page
import 'package:soifapp/admins_pages/add_haircut_service_page.dart'; // Importer la page d'ajout de service
import 'package:soifapp/coiffeurs_page/coiffeur_home_page.dart'; // Importer pour voir le planning
import 'package:soifapp/admins_pages/admin_delete_sub_category_page.dart'; // Importer la nouvelle page
import 'package:soifapp/admins_pages/admin_edit_service_page.dart';
import 'package:soifapp/admins_pages/admin_edit_sub_category_page.dart';
import 'package:soifapp/admins_pages/admin_manage_services_page.dart'; // Importer la page de gestion des services
import 'package:soifapp/admins_pages/admin_delete_coiffeur_page.dart';
import 'package:soifapp/admins_pages/manage_absences_page.dart'; // Importer la page de gestion des absences
import 'package:soifapp/admins_pages/sign_up_page.dart';
import 'package:soifapp/widgets/logout_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActiveCoiffeurInfo {
  final String userId;
  final String name;

  ActiveCoiffeurInfo({required this.userId, required this.name});
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<ActiveCoiffeurInfo> _activeCoiffeurs = [];
  bool _isLoadingCoiffeurs = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchActiveCoiffeurs();
  }

  Future<void> _fetchActiveCoiffeurs() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCoiffeurs = true;
      _errorMessage = null;
    });

    try {
      // 1. Récupérer les coiffeurs actifs de la table 'coiffeurs'
      final activeCoiffeursResponse =
          await _supabase.from('coiffeurs').select('user_id').eq('actif', true);

      final List<Map<String, dynamic>> activeCoiffeursData =
          List<Map<String, dynamic>>.from(activeCoiffeursResponse);

      if (activeCoiffeursData.isEmpty) {
        if (mounted) {
          setState(() {
            _activeCoiffeurs = [];
            _isLoadingCoiffeurs = false;
          });
        }
        return;
      }

      final List<String> userIds =
          activeCoiffeursData.map((c) => c['user_id'] as String).toList();

      // 2. Récupérer les noms de ces coiffeurs depuis la table 'profiles'
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, nom')
          .filter(
              'id', 'in', userIds); // Utiliser filter() comme alternative à in_

      final List<Map<String, dynamic>> profilesData =
          List<Map<String, dynamic>>.from(profilesResponse);
      final Map<String, String> userIdToNameMap = {
        for (var profile in profilesData)
          profile['id'] as String: profile['nom'] as String? ?? 'Nom Inconnu'
      };

      final List<ActiveCoiffeurInfo> fetchedCoiffeurs = [];
      for (var coiffeurData in activeCoiffeursData) {
        final userId = coiffeurData['user_id'] as String;
        if (userIdToNameMap.containsKey(userId)) {
          fetchedCoiffeurs.add(ActiveCoiffeurInfo(
            userId: userId,
            name: userIdToNameMap[userId]!,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _activeCoiffeurs = fetchedCoiffeurs;
          _isLoadingCoiffeurs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print("Erreur fetchActiveCoiffeurs: $e");
        setState(() {
          _errorMessage =
              "Erreur lors de la récupération des coiffeurs actifs: ${e.toString()}";
          _isLoadingCoiffeurs = false;
        });
      }
    }
  }

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

  Widget _buildDashboardGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
            icon: Icons.group_add_outlined,
            title: 'Gérer les coiffeurs',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageCoiffeursPage()))),
        _buildActionCard(
            context: context,
            icon: Icons.event_busy_outlined,
            title: 'Gérer les absences',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageAbsencesPage()))),
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
        // Placeholder pour garder la grille alignée si besoin
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Administrateur'),
        actions: const [LogoutButton()],
        elevation: 0,
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _fetchActiveCoiffeurs,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Tableau de bord',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            _buildDashboardGrid(context),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text("Coiffeurs Actifs",
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface)),
            ),
            _buildActiveCoiffeursList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCoiffeursList() {
    if (_isLoadingCoiffeurs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
          child:
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_activeCoiffeurs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
            child: Text(
          "Aucun coiffeur actif pour le moment.",
          textAlign: TextAlign.center,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        )),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activeCoiffeurs.length,
      itemBuilder: (context, index) {
        final coiffeur = _activeCoiffeurs[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(coiffeur.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Voir le planning",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: Theme.of(context).colorScheme.primary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoiffeurHomePage(
                    coiffeurUserIdFromAdmin: coiffeur.userId,
                    coiffeurNameFromAdmin: coiffeur.name,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
