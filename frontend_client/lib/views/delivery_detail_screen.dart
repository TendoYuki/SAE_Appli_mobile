import 'package:flutter/material.dart';

class DeliveryDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la Livraison'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Panier de légumes - 15/02/2025",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Status : Livré", style: TextStyle(fontSize: 18, color: Colors.green)),
            const SizedBox(height: 20),
            const Text("Contenu du panier :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("- Carottes\n- Pommes de terre\n- Salade\n- Tomates"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF388E3C)),
              child: const Text("Retour"),
            ),
          ],
        ),
      ),
    );
  }
}
