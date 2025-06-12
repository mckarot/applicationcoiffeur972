import 'package:flutter/material.dart';

class CoiffeurHomePage extends StatelessWidget {
  const CoiffeurHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espace Coiffeur')),
      body: const Center(child: Text('Bienvenue, coiffeur !')),
    );
  }
}
