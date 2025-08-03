import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Using a simple class for coiffeur info, similar to other admin pages.
class CoiffeurInfo {
  final String userId;
  final String name;

  CoiffeurInfo({required this.userId, required this.name});
}

class AdminDeleteCoiffeurPage extends StatefulWidget {
  const AdminDeleteCoiffeurPage({super.key});

  @override
  State<AdminDeleteCoiffeurPage> createState() =>
      _AdminDeleteCoiffeurPageState();
}

class _AdminDeleteCoiffeurPageState extends State<AdminDeleteCoiffeurPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1'); // Adaptez la région si besoin
  List<CoiffeurInfo> _coiffeurs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCoiffeurs();
  }

  Future<void> _fetchCoiffeurs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Récupérer tous les utilisateurs avec le rôle 'coiffeur' depuis Firestore
      final coiffeursSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coiffeur')
          .get();

      final List<CoiffeurInfo> fetchedCoiffeurs = coiffeursSnapshot.docs
          .map((profile) => CoiffeurInfo(
                userId: profile.id,
                name: profile.data()['nom'] as String? ?? 'Nom Inconnu',
              ))
          .toList();

      if (mounted) {
        setState(() {
          _coiffeurs = fetchedCoiffeurs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print("Erreur fetchCoiffeurs for deletion: $e");
        setState(() {
          _errorMessage =
              "Erreur lors de la récupération des coiffeurs: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCoiffeur(String userId, String name) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Voulez-vous vraiment supprimer le coiffeur "$name" ?\n\nCette action est irréversible et supprimera définitivement son compte, son profil et ses données associées (horaires, etc.). Ses rendez-vous existants seront conservés mais ne lui seront plus attribués.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      // Appel de la Cloud Function pour une suppression sécurisée
      final HttpsCallable callable =
          _functions.httpsCallable('deleteUserAndData');
      final result = await callable.call<Map<String, dynamic>>({
        'uid': userId,
      });

      print(result.data['message']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Le coiffeur "$name" a été supprimé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchCoiffeurs(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supprimer un Coiffeur'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCoiffeurs,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red)))
                : _coiffeurs.isEmpty
                    ? const Center(child: Text("Aucun coiffeur à supprimer."))
                    : ListView.builder(
                        itemCount: _coiffeurs.length,
                        itemBuilder: (context, index) {
                          final coiffeur = _coiffeurs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: Icon(Icons.person_outline,
                                  color: Theme.of(context).colorScheme.primary),
                              title: Text(coiffeur.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_forever,
                                    color: Colors.redAccent),
                                onPressed: () => _deleteCoiffeur(
                                    coiffeur.userId, coiffeur.name),
                                tooltip: 'Supprimer ${coiffeur.name}',
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
