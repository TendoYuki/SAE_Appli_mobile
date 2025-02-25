import 'package:flutter/material.dart';
import 'pages/tournee_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion des Tournées',
      theme: ThemeData(primarySwatch: Colors.green),
      home: TourneePage(),
    );
  }
}
