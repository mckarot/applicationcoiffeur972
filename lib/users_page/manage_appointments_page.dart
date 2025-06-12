import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour le formatage de la date

// Un modèle simple pour représenter un rendez-vous
class Appointment {
  String id;
  DateTime date;
  String timeSlot;
  String coiffeur;
  String service;

  Appointment({
    required this.id,
    required this.date,
    required this.timeSlot,
    required this.coiffeur,
    required this.service,
  });
}

class ManageAppointmentsPage extends StatefulWidget {
  const ManageAppointmentsPage({super.key});

  @override
  State<ManageAppointmentsPage> createState() => _ManageAppointmentsPageState();
}

class _ManageAppointmentsPageState extends State<ManageAppointmentsPage> {
  // Liste fictive de rendez-vous
  final List<Appointment> _appointments = [
    Appointment(
        id: '1',
        date: DateTime.now().add(const Duration(days: 3)),
        timeSlot: '10:00 - 10:45',
        coiffeur: 'Sophie',
        service: 'Coupe Femme'),
    Appointment(
        id: '2',
        date: DateTime.now().add(const Duration(days: 7)),
        timeSlot: '14:00 - 14:45',
        coiffeur: 'Julien',
        service: 'Coupe Homme + Barbe'),
    Appointment(
        id: '3',
        date: DateTime.now().add(const Duration(days: 10)),
        timeSlot: '16:00 - 17:30',
        coiffeur: 'Chloé',
        service: 'Couleur & Mèches'),
  ];

  void _cancelAppointment(String appointmentId) {
    setState(() {
      _appointments.removeWhere((app) => app.id == appointmentId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rendez-vous annulé avec succès.'),
        backgroundColor: Colors.red[400],
      ),
    );
  }

  void _modifyAppointment(Appointment appointment) {
    // Pour une vraie modification, vous naviguerez vers une page d'édition
    // ou afficherez un dialogue permettant de changer les détails.
    // Ici, nous allons juste afficher un message.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Modification du RDV avec ${appointment.coiffeur} (fictif).'),
        backgroundColor: Colors.orange[400],
      ),
    );
    // Exemple: Naviguer vers la page de réservation avec les infos pré-remplies
    // Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(editingAppointment: appointment)));
  }

  @override
  Widget build(BuildContext context) {
    // S'assurer que intl est initialisé si vous utilisez des formats localisés complexes
    // Pour DateFormat.yMMMMd(), la localisation par défaut devrait suffire.
    final DateFormat dateFormat = DateFormat.yMMMMd('fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Rendez-vous'),
        backgroundColor: Colors.pink[100],
        iconTheme: IconThemeData(color: Colors.pink[700]),
      ),
      body: _appointments.isEmpty
          ? Center(
              child: Text(
                'Vous n\'avez aucun rendez-vous programmé.',
                style: TextStyle(fontSize: 18, color: Colors.pink[300]),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appointment = _appointments[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  color: Colors.pink[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15.0),
                    title: Text(
                      '${appointment.service} avec ${appointment.coiffeur}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.pink[700],
                          fontSize: 17),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Le ${dateFormat.format(appointment.date)}\nÀ ${appointment.timeSlot}',
                        style: TextStyle(color: Colors.pink[500], fontSize: 15),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue[400]),
                          tooltip: 'Modifier',
                          onPressed: () => _modifyAppointment(appointment),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel_outlined,
                              color: Colors.red[400]),
                          tooltip: 'Annuler',
                          onPressed: () => _cancelAppointment(appointment.id),
                        ),
                      ],
                    ),
                    isThreeLine:
                        true, // Permet plus d'espace pour le sous-titre
                  ),
                );
              },
            ),
    );
  }
}
