import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/pet_provider.dart';
import 'providers/reminder_provider.dart';
import 'screens/home_screen.dart';
import 'screens/news_screen.dart';
import 'screens/care_screen.dart';
import 'screens/breed_list_screen.dart';
import 'screens/profile_screen_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PetCareApp());
}

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: MaterialApp(
        title: 'PetCare',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          scaffoldBackgroundColor: const Color(0xFFFDF9F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFDF9F5),
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.brown,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: Colors.brown),
            actionsIconTheme: IconThemeData(color: Colors.brown),
          ),
        ),
        home: const MainNavigation(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2;

  final List<String> _titles = [
    'Notícias',
    'Cuidados',
    'Início',
    'Raças',
    'Perfil',
  ];

  final List<Widget> _screens = [
    NewsScreen(),
    CareScreen(),
    HomeScreen(),
    BreedListScreen(),
    ProfileScreenMain(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (_currentIndex == 2 || _currentIndex == 4)
          ? null
          : AppBar(
              title: Text(_titles[_currentIndex]),
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.brown[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/news_paw.png', width: 28, height: 28),
            label: 'Notícias',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/icons/heart_cross.png', width: 28, height: 28),
            label: 'Cuidados',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Raças'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Perfil'),
        ],
      ),
    );
  }
}
