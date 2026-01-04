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
import 'package:soifapp/admins_pages/admin_dashboard_page.dart'; // Importer la nouvelle page de tableau de bord
import 'package:soifapp/widgets/logout_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      // Récupérer les coiffeurs actifs directement depuis la collection 'users'
      final coiffeursSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coiffeur')
          .where('actif', isEqualTo: true)
          .get();

      final List<ActiveCoiffeurInfo> fetchedCoiffeurs =
          coiffeursSnapshot.docs.map((doc) {
        final data = doc.data();
        return ActiveCoiffeurInfo(
          userId: doc.id,
          name: data['nom'] as String? ?? 'Nom Inconnu',
        );
      }).toList();

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return _buildDesktopLayout(context, theme);
            } else {
              return _buildMobileLayout(context, theme);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Text(
                'Tableau de bord',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.dashboard),
                onPressed: () {
                  _showPasswordDialog();
                },
              ),
            ],
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
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Panneau des actions à gauche
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(
                          'Tableau de bord',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.dashboard),
                          onPressed: () {
                            _showPasswordDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildDashboardGrid(context),
                ],
              ),
            ),
          ),
        ),
        // Séparateur
        const VerticalDivider(
          width: 1,
          thickness: 1,
        ),
        // Liste des coiffeurs à droite
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Coiffeurs Actifs",
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface)),
                  ),
                  const SizedBox(height: 8),
                  _buildActiveCoiffeursList(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const String _dashboardPassword = '2610'; // Mot de passe pour accéder au tableau de bord

  void _showPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Accès restreint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Veuillez entrer le mot de passe pour accéder à cette page :'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fermer la boîte de dialogue
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                if (passwordController.text == _dashboardPassword) {
                  Navigator.of(dialogContext).pop(); // Fermer la boîte de dialogue
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardPage(),
                    ),
                  );
                } else {
                  // Afficher un message d'erreur
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mot de passe incorrect'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
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
