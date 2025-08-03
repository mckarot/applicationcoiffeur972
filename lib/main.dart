import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import pour l'initialisation des locales
import 'package:flutter_localizations/flutter_localizations.dart'; // Import pour les delegates
import 'package:provider/provider.dart';
// Importez la nouvelle page
import 'package:soifapp/firebase_options.dart';
import 'package:soifapp/models/theme_provider.dart';
import 'package:soifapp/welcome_page.dart';
import 'package:firebase_core/firebase_core.dart'; // Importer Firebase
import 'package:timezone/data/latest.dart' as tz; // Import pour timezone

void main() async {
  // La fonction main devient async
  WidgetsFlutterBinding
      .ensureInitialized(); // Nécessaire si vous initialisez des choses avant runApp

  // Initialisation de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Utilise le fichier firebase_options.dart
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

    // Thème Clair (moderne, basé sur le bleu)
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blue[800],
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue[700],
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.blue[800]!,
        secondary: Colors.blueAccent[400]!,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black87,
        error: Colors.redAccent,
        onError: Colors.white,
        surfaceContainerHighest: Colors.blue[50],
        outlineVariant: Colors.blue[200],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      )),
      useMaterial3: true,
    );

    // Thème Sombre (moderne, basé sur le bleu)
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.blue[300],
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
        iconTheme: IconThemeData(color: Colors.blue[300]),
        titleTextStyle: TextStyle(
            color: Colors.blue[200], fontSize: 20, fontWeight: FontWeight.bold),
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.blue[400]!,
        secondary: Colors.blueAccent[200]!,
        surface: Colors.grey[850]!,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white70,
        error: Colors.red[400]!,
        onError: Colors.black,
        surfaceContainerHighest: Colors.grey[800]!,
        outlineVariant: Colors.grey[700]!,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      )),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: const WelcomePage(),
    );
  }
}
