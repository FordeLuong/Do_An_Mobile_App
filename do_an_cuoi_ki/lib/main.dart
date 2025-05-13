import 'package:do_an_cuoi_ki/firebase_options.dart';
import 'package:do_an_cuoi_ki/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/auth/register_screen.dart';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  void checkConnection() async{
    bool isConnected = await Firebase.apps.isNotEmpty;
    print('FireBase connection : $isConnected');
  }
  checkConnection();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final navigatorKey = GlobalKey<NavigatorState>();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home:RegisterPage() ,
      initialRoute: '',
      routes: {
        '/login': (context) =>  LoginPage(),

        //MyListDeTai
      },
    );  
  }
}
