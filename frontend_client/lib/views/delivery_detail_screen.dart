import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DeliveryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;
  DeliveryDetailScreen({Key? key, required this.delivery}) : super(key: key);

  @override
  _DeliveryDetailScreenState createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  Timer? _timer;
  int _lastNotificationCount = 0;
  bool _hasNewNotification = false;

  @override
  void initState() {
    super.initState();
    _startNotificationPolling();
  }

  void _startNotificationPolling() {
    _fetchNotifications(); // Vérification initiale
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
    // Remplacez par l'URL appropriée
    final url = Uri.parse("http://127.0.0.1:5000/notifications");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> notifications = jsonDecode(response.body);
        if (notifications.length > _lastNotificationCount) {
          setState(() {
            _hasNewNotification = true;
          });
        }
        _lastNotificationCount = notifications.length;
      } else {
        print("Erreur lors de la récupération: ${response.body}");
      }
    } catch (e) {
      print("Erreur lors de la requête: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _clearNotificationFlag() {
    setState(() {
      _hasNewNotification = false;
    });
    Navigator.pushNamed(context, '/notifications');
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> paniers = widget.delivery['paniers'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la Livraison'),
        backgroundColor: const Color(0xFF388E3C),
        actions: [
          IconButton(
            onPressed: _clearNotificationFlag,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications, color: Colors.grey),
                if (_hasNewNotification)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.delivery['delivery'] ?? "Livraison inconnue",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Status : ${widget.delivery['status'] ?? "Inconnu"}",
              style: TextStyle(
                fontSize: 18,
                color: (widget.delivery['status'] ?? "") == "Livré"
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Date : ${widget.delivery['timestamp'] ?? ""}",
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
                : const Text("Aucun détail de panier disponible.",
                    style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C)),
              child: const Text("Retour"),
            ),
          ],
        ),
      ),
    );
  }
}
