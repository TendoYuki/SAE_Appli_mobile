import 'package:flutter/material.dart';
import 'notification_screen.dart';
import 'delivery_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Livraisons'),
        backgroundColor: const Color(0xFF388E3C),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          DeliveryCard(
            deliveryTitle: "Panier de légumes - 15/02/2025",
            status: "Livré",
            onTap: () => Navigator.pushNamed(context, '/delivery'),
          ),
          DeliveryCard(
            deliveryTitle: "Panier fruits & légumes - 20/02/2025",
            status: "En cours",
            onTap: () => Navigator.pushNamed(context, '/delivery'),
          ),
        ],
      ),
    );
  }
}

class DeliveryCard extends StatelessWidget {
  final String deliveryTitle;
  final String status;
  final VoidCallback onTap;

  const DeliveryCard({
    required this.deliveryTitle,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      child: ListTile(
        title: Text(deliveryTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status, style: TextStyle(color: status == "Livré" ? Colors.green : Colors.orange)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
