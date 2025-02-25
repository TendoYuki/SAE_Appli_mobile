import 'package:flutter/material.dart';
import 'views/splash_screen.dart';
import 'views/home_screen.dart';
import 'views/delivery_detail_screen.dart';
import 'views/notification_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Les Jardins de Cocagne - Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF388E3C),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(),
        '/delivery': (context) => DeliveryDetailScreen(),
        '/notifications': (context) => NotificationScreen(),
      },
    );
  }
}
