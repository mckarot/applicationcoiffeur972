import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soifapp/admins_pages/activate_coiffeur_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CoiffeurManagementInfo {
  final String uid;
  final String name;
  final bool isActive;

  CoiffeurManagementInfo(
      {required this.uid, required this.name, required this.isActive});

  factory CoiffeurManagementInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoiffeurManagementInfo(
      uid: doc.id,
      name: data['nom'] ?? 'Nom inconnu',
      isActive: data['actif'] ?? false,
    );
  }
}

class ManageCoiffeursPage extends StatefulWidget {
  const ManageCoiffeursPage({super.key});

  @override
  State<ManageCoiffeursPage> createState() => _ManageCoiffeursPageState();
}

class _ManageCoiffeursPageState extends State<ManageCoiffeursPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CoiffeurManagementInfo> _coiffeurs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAllCoiffeurs();
  }

  Future<void> _fetchAllCoiffeurs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Récupérer tous les utilisateurs avec le rôle 'coiffeur' depuis la collection 'users'
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coiffeur')
          .get();

      final fetchedCoiffeurs = querySnapshot.docs
          .map((doc) => CoiffeurManagementInfo.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _coiffeurs = fetchedCoiffeurs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur lors de la récupération des coiffeurs: $e";
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
              : _coiffeurs.isEmpty
                  ? const Center(child: Text("Aucun coiffeur trouvé."))
                  : RefreshIndicator(
                      onRefresh: _fetchAllCoiffeurs,
                      child: ListView.builder(
                        itemCount: _coiffeurs.length,
                        itemBuilder: (context, index) {
                          final coiffeur = _coiffeurs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              title: Text(coiffeur.name),
                              subtitle: Text(
                                coiffeur.isActive
                                    ? 'Statut: Actif'
                                    : 'Statut: En attente d\'activation',
                                style: TextStyle(
                                  color: coiffeur.isActive
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: ElevatedButton(
                                child: Text(coiffeur.isActive
                                    ? 'Modifier'
                                    : 'Activer'),
                                onPressed: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ActivateCoiffeurPage(
                                        userId: coiffeur.uid,
                                        userName: coiffeur.name,
                                      ),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    _fetchAllCoiffeurs();
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
