import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'delivery_detail_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> deliveries = [];
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
    // Rafraîchissement toutes les 5 secondes pour mettre à jour l'historique
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchDeliveries();
    });
  }

  Future<void> _fetchDeliveries() async {
    // Pour un émulateur Android, utilisez http://10.0.2.2:5000/notifications
    final url = Uri.parse("http://127.0.0.1:5000/notifications");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          deliveries = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("Erreur lors de la récupération des livraisons: ${response.body}");
        setState(() { isLoading = false; });
      }
    } catch (e) {
      print("Erreur lors de la requête des livraisons: $e");
      setState(() { isLoading = false; });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord des Livraisons'),
        backgroundColor: const Color(0xFF388E3C),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
          onRefresh: _fetchDeliveries,
          child: deliveries.isEmpty
            ? ListView(
                children: [Center(child: Text("Aucune livraison enregistrée."))],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  var delivery = deliveries[index];
                  String deliveryTitle = delivery['delivery'] ?? "Livraison inconnue";
                  String status = delivery['status'] ?? "";
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 4,
                    child: ListTile(
                      title: Text(deliveryTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        status,
                        style: TextStyle(color: status == "Livré" ? Colors.green : Colors.orange),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DeliveryDetailScreen(delivery: delivery),
                        ));
                      },
                    ),
                  );
                },
              ),
        ),
    );
  }
}
