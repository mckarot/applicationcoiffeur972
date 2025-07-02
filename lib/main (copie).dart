import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import pour l'initialisation des locales
import 'package:flutter_localizations/flutter_localizations.dart'; // Import pour les delegates
import 'package:provider/provider.dart';
import 'package:soifapp/auth_page.dart'; // Importez la nouvelle page
import 'package:soifapp/models/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importer Supabase
import 'package:timezone/data/latest.dart' as tz; // Import pour timezone

void main() async {
  // La fonction main devient async
  WidgetsFlutterBinding
      .ensureInitialized(); // Nécessaire si vous initialisez des choses avant runApp

  // Initialisation de Supabase
  await Supabase.initialize(
    url:
        'https://dxmnthkrdtlgdepujtmh.supabase.co', // Remplacez par votre URL Supabase
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4bW50aGtyZHRsZ2RlcHVqdG1oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk3NDk1MzIsImV4cCI6MjA2NTMyNTUzMn0.g2H3BamnTq2mGDcTwzYtU0yYAKFccWfaqmZFBEcKARg', // Remplacez par votre clé Anon Supabase
  );

  // Initialisation des données de fuseau horaire pour le package timezone
  tz.initializeTimeZones();

  // Initialisation des données de localisation pour intl (dates, etc.)
  await initializeDateFormatting(
      'fr_FR', null); // Initialise les données pour la locale française

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Thème Clair (basé sur vos couleurs roses)
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.pink[400],
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.pink[100],
        iconTheme: IconThemeData(color: Colors.pink[700]),
        titleTextStyle: TextStyle(
            color: Colors.pink[800], fontSize: 20, fontWeight: FontWeight.bold),
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.pink[400]!,
        secondary: Colors.pinkAccent[200]!,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black87,
        error: Colors.redAccent,
        onError: Colors.white,
        // Couleurs spécifiques pour les containers de surface (utilisé dans BookingPage)
        surfaceContainerHighest: Colors.pink[50], // Très clair
        outlineVariant: Colors.pink[200], // Pour les bordures
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink[300],
        foregroundColor: Colors.white,
      )),
      useMaterial3: true,
    );

    // Thème Sombre
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor:
          Colors.pink[700], // Un rose plus soutenu pour le mode sombre
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
        iconTheme: IconThemeData(color: Colors.pink[300]),
        titleTextStyle: TextStyle(
            color: Colors.pink[200], fontSize: 20, fontWeight: FontWeight.bold),
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.pink[600]!,
        secondary: Colors.pinkAccent[100]!,
        surface: Colors.grey[800]!,
        onPrimary: Colors.black, // Texte sur fond primaire sombre
        onSecondary: Colors.black,
        onSurface: Colors.white70,
        error: Colors.red[400]!,
        onError: Colors.black,
        // Couleurs spécifiques pour les containers de surface en mode sombre
        surfaceContainerHighest: Colors.grey[700]!, // Un gris plus foncé
        outlineVariant: Colors.grey[600]!, // Pour les bordures
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink[500],
        foregroundColor: Colors.white,
      )),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'CoifApp',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // Anglais
        Locale('fr', ''), // Français
        // ... autres locales supportées
      ],
      home: const AuthPage(),
    );
  }
}
