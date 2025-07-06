import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/theme.dart';
import 'providers/character_provider.dart';
import 'services/character_service.dart';
import 'services/card_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(RealmOfValorApp(prefs: prefs));
}

class RealmOfValorApp extends StatelessWidget {
  final SharedPreferences prefs;

  const RealmOfValorApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<SharedPreferences>.value(value: prefs),
        Provider<CharacterService>(
          create: (context) => CharacterService(prefs),
        ),
        Provider<CardService>(
          create: (context) => CardService(prefs),
        ),
        
        // State Providers
        ChangeNotifierProvider<CharacterProvider>(
          create: (context) => CharacterProvider(
            context.read<CharacterService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Realm of Valor',
        debugShowCheckedModeBanner: false,
        theme: RealmOfValorTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
