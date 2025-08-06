import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soifapp/auth_page.dart';
import 'package:soifapp/users_page/booking_page.dart';
import 'package:soifapp/coiffeurs_page/coiffeur_home_page.dart';
import 'package:soifapp/admins_pages/admin_home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si l'utilisateur n'est pas connecté, on affiche la page de connexion
        if (!snapshot.hasData) {
          return const AuthPage();
        }

        // Si l'utilisateur est connecté, on affiche un écran de chargement
        // pendant qu'on récupère son rôle
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userDocSnapshot.hasError || !userDocSnapshot.data!.exists) {
               // En cas d'erreur ou si le document n'existe pas, on déconnecte
               // l'utilisateur par sécurité et on le renvoie à la page de connexion.
               FirebaseAuth.instance.signOut();
               return const AuthPage();
            }

            final data = userDocSnapshot.data!.data() as Map<String, dynamic>;
            final role = data['role'] ?? 'client'; // Rôle par défaut

            if (role == 'client') {
              return const BookingPage();
            } else if (role == 'coiffeur') {
              return const CoiffeurHomePage();
            } else if (role == 'admin') {
              return const AdminHomePage();
            }
            
            // Fallback vers la page par défaut si le rôle est inconnu
            return const BookingPage();
          },
        );
      },
    );
  }
}

