import 'package:flutter/material.dart';
import 'package:soifapp/admins_pages/activate_coiffeur_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingCoiffeurInfo {
  final String userId;
  final String name;
  final String? email; // Email peut être utile à afficher

  PendingCoiffeurInfo({required this.userId, required this.name, this.email});
}

class ManageCoiffeursPage extends StatefulWidget {
  const ManageCoiffeursPage({super.key});

  @override
  State<ManageCoiffeursPage> createState() => _ManageCoiffeursPageState();
}

class _ManageCoiffeursPageState extends State<ManageCoiffeursPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<PendingCoiffeurInfo> _pendingCoiffeurs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingCoiffeurs();
  }

  Future<void> _fetchPendingCoiffeurs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Récupérer tous les utilisateurs avec le rôle 'coiffeur' depuis 'profiles'
      final profilesResponse = await _supabase
          .from('profiles')
          .select(
              'id, nom') // On ne sélectionne plus user_email car il n'est pas dans cette table
          .eq('role', 'coiffeur');

      // 2. Récupérer tous les user_id des coiffeurs déjà actifs/configurés dans la table 'coiffeurs'
      final activeCoiffeursResponse =
          await _supabase.from('coiffeurs').select('user_id');

      final List<Map<String, dynamic>> allCoiffeurProfiles =
          List<Map<String, dynamic>>.from(profilesResponse);
      final List<Map<String, dynamic>> activeCoiffeurs =
          List<Map<String, dynamic>>.from(activeCoiffeursResponse);

      final Set<String> activeCoiffeurUserIds =
          activeCoiffeurs.map((c) => c['user_id'] as String).toSet();

      final List<PendingCoiffeurInfo> pending = [];
      for (var profile in allCoiffeurProfiles) {
        if (!activeCoiffeurUserIds.contains(profile['id'] as String)) {
          pending.add(PendingCoiffeurInfo(
            userId: profile['id'] as String,
            name: profile['nom'] as String? ?? 'Nom inconnu',
            email:
                null, // L'email n'est pas récupéré directement depuis profiles
          ));
        }
      }

      if (mounted) {
        setState(() {
          _pendingCoiffeurs = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print("Erreur fetchPendingCoiffeurs: $e");
        setState(() {
          _errorMessage =
              "Erreur lors de la récupération des coiffeurs en attente: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gérer les Coiffeurs"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : _pendingCoiffeurs.isEmpty
                  ? const Center(
                      child: Text("Aucun coiffeur en attente d'activation."))
                  : RefreshIndicator(
                      onRefresh: _fetchPendingCoiffeurs,
                      child: ListView.builder(
                        itemCount: _pendingCoiffeurs.length,
                        itemBuilder: (context, index) {
                          final coiffeur = _pendingCoiffeurs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              title: Text(coiffeur.name),
                              subtitle:
                                  Text(coiffeur.email ?? 'Email non fourni'),
                              trailing: ElevatedButton(
                                child: const Text('Activer'),
                                onPressed: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ActivateCoiffeurPage(
                                        userId: coiffeur.userId,
                                        userName: coiffeur.name,
                                      ),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    _fetchPendingCoiffeurs(); // Recharger la liste
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
