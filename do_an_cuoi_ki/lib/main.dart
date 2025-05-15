import 'package:do_an_cuoi_ki/firebase_options.dart';
import 'package:do_an_cuoi_ki/screens/auth/login_screen.dart';
import 'package:do_an_cuoi_ki/screens/auth/register_screen.dart';
import 'package:do_an_cuoi_ki/screens/owner/add_room_screen.dart';
import 'package:do_an_cuoi_ki/screens/owner/room_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/user/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  void checkConnection() async {
    bool isConnected = await Firebase.apps.isNotEmpty;
    print('FireBase connection : $isConnected');
  }
  checkConnection();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      initialRoute: '/add_building',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
         '/add_building': (context) => const BuildingListScreen(),
      },
    );
  }
}