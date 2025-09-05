import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  final FirebaseFunctions _functions = 
      FirebaseFunctions.instanceFor(region: 'europe-west1');
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
      final coiffeursSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coiffeur')
          .orderBy('nom')
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
        setState(() {
          _errorMessage = "Erreur: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCoiffeur(String userId, String name) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Voulez-vous vraiment supprimer le coiffeur "$name" ?\n\nCette action est irréversible et supprimera définitivement son compte et ses données associées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer Définitivement'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final HttpsCallable callable = 
          _functions.httpsCallable('deleteUserAndData');
      await callable.call<Map<String, dynamic>>({'uid': userId});

      Navigator.of(context).pop(); // Dismiss loading indicator

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Le coiffeur "$name" a été supprimé.'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchCoiffeurs(); // Refresh the list
      }
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loading indicator
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }
    if (_coiffeurs.isEmpty) {
      return _buildEmptyState();
    }
    return _buildCoiffeurList();
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 60),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700], fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Réessayer"),
              onPressed: _fetchCoiffeurs,
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onError,
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Aucun coiffeur à supprimer.",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCoiffeurList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _coiffeurs.length,
      itemBuilder: (context, index) {
        final coiffeur = _coiffeurs[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              coiffeur.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_forever, color: Colors.redAccent[400]),
              onPressed: () => _deleteCoiffeur(coiffeur.userId, coiffeur.name),
              tooltip: 'Supprimer ${coiffeur.name}',
            ),
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2);
      },
    );
  }
}
