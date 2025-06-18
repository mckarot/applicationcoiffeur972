import 'package:flutter/material.dart';
import 'package:soifapp/admins_pages/manage_coiffeurs_page.dart'; // Importer la nouvelle page
import 'package:soifapp/admins_pages/add_haircut_service_page.dart'; // Importer la page d'ajout de service
import 'package:soifapp/coiffeurs_page/coiffeur_home_page.dart'; // Importer pour voir le planning
import 'package:soifapp/admins_pages/admin_delete_sub_category_page.dart'; // Importer la nouvelle page
import 'package:soifapp/admins_pages/admin_manage_services_page.dart'; // Importer la page de gestion des services
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Administrateur'),
        actions: const [LogoutButton()],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchActiveCoiffeurs,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Gérer les Demandes Coiffeurs'),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManageCoiffeursPage()));
              },
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
            ),
            const SizedBox(height: 16), // Espace entre les boutons
            ElevatedButton.icon(
              icon: const Icon(Icons
                  .add_shopping_cart_outlined), // Icône pour ajouter un service
              label: const Text('Ajouter un Service de Coiffure'),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddHaircutServicePage()));
              },
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('Gérer les Services Existants'),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminManageServicesPage()));
              },
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Colors.redAccent),
              label: const Text('Supprimer une Sous-Catégorie'),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AdminDeleteSubCategoryPage()));
              },
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
            ),
            const SizedBox(height: 20),
            Text("Coiffeurs Actifs :",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 10),
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
      return const Center(child: Text("Aucun coiffeur actif pour le moment."));
    }
    return ListView.builder(
      shrinkWrap: true, // Important dans un ListView parent
      physics:
          const NeverScrollableScrollPhysics(), // Important dans un ListView parent
      itemCount: _activeCoiffeurs.length,
      itemBuilder: (context, index) {
        final coiffeur = _activeCoiffeurs[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: Icon(Icons.person_outline,
                color: Theme.of(context).colorScheme.secondary),
            title: Text(coiffeur.name),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
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
