import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sdui_with_firestore/screens/ecommerce_catalog_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with mock/default options for local emulator usage
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'mock-api-key',
        appId: 'mock-app-id',
        messagingSenderId: 'mock-sender-id',
        projectId: 'demo-sdui-firestore',
      ),
    );

    // Set emulator host address depending on Platform
    String host = 'localhost';
    if (!kIsWeb && Platform.isAndroid) {
      host = '10.0.2.2';
    }

    // Configure Firestore to connect to local emulator on port 8080
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);

    // Enable offline persistence settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    // Start persistent sync of SDUI templates collection to keep local cache updated in real-time
    FirebaseFirestore.instance
        .collection('sdui_templates')
        .snapshots()
        .listen((_) {});
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const SduiEcommerceApp());
}

class SduiEcommerceApp extends StatelessWidget {
  const SduiEcommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDUI Ecommerce',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const EcommerceCatalogScreen(),
    );
  }
}
