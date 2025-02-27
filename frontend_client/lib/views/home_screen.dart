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
  int _lastNotificationCount = 0;
  bool _hasNewNotification = false;

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchDeliveries();
    });
  }

  Future<void> _fetchDeliveries() async {
    // Pour un émulateur Android, utilisez http://10.0.2.2:5000/notifications
    // Ici, on utilise l'URL de votre API. Adaptez-la selon votre configuration.
    final url = Uri.parse("http://127.0.0.1:5000/notifications");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> fetched = jsonDecode(response.body);
        // Si le nombre de notifications a augmenté, on active l'indicateur
        if (fetched.length > _lastNotificationCount) {
          setState(() {
            _hasNewNotification = true;
          });
        }
        _lastNotificationCount = fetched.length;
        setState(() {
          deliveries = fetched;
          isLoading = false;
        });
      } else {
        print("Erreur lors de la récupération des livraisons: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur lors de la requête: $e");
      setState(() {
        isLoading = false;
      });
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotificationScreen()),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord des Livraisons'),
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
