import 'package:flutter/material.dart';

class DeliveryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> delivery;
  DeliveryDetailScreen({Key? key, required this.delivery}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // On attend que l'objet "delivery" contienne une clé "paniers"
    List<dynamic> paniers = delivery['paniers'] ?? [];

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
            Text(
              delivery['delivery'] ?? "Livraison inconnue",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Status : ${delivery['status'] ?? "Inconnu"}",
              style: TextStyle(
                fontSize: 18,
                color: (delivery['status'] ?? "") == "Livré" ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Date : ${delivery['timestamp'] ?? ""}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text("Contenu de la livraison au dépôt :",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            paniers.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: paniers.map<Widget>((panier) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "${panier['nom']}: ${panier['quantite']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                  )
                : const Text("Aucun détail de panier disponible.", style: TextStyle(fontSize: 16)),
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
