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

  int mois = DateTime.now().month;
  List<String> months = [
    "Janvier",
    "Février",
    "Mars",
    "Avril",
    "Mai",
    "Juin",
    "Juillet",
    "Aout",
    "Septembre",
    "Octobre",
    "Novembre",
    "Décembre"
  ];

  // Variables pour la composition des paniers (récupérée via l'API)
  Map<String, dynamic>? basketData;
  bool isLoadingBasket = true;

  @override
  void initState() {
    super.initState();
    _startNotificationPolling();
    _fetchBasketComposition();
  }

  // Polling pour les notifications (toutes les 5 secondes)
  void _startNotificationPolling() {
    _fetchNotifications(); // Vérification initiale
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
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
        print("Erreur lors de la récupération des notifications: ${response.body}");
      }
    } catch (e) {
      print("Erreur lors de la requête des notifications: $e");
    }
  }

  // Appel à l'API pour récupérer la composition des paniers pour le mois courant
  Future<void> _fetchBasketComposition() async {
    final url = Uri.parse("http://127.0.0.1:5000/basket?mois=${months[mois - 1]}");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          basketData = data;
          isLoadingBasket = false;
        });
      } else {
        print("Erreur lors de la récupération de la composition: ${response.body}");
        setState(() {
          isLoadingBasket = false;
        });
      }
    } catch (e) {
      print("Erreur lors de la requête de composition: $e");
      setState(() {
        isLoadingBasket = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Réinitialise le flag de notification et navigue vers la page des notifications
  void _clearNotificationFlag() {
    setState(() {
      _hasNewNotification = false;
    });
    Navigator.pushNamed(context, '/notifications');
  }

  // Construit une Card pour afficher la composition d'un type de panier
  // Chaque ligne affiche le nom du légume et la quantité convertie en grammes (quantité en kg * 1000)
  Widget _buildBasketCard(String title, List<dynamic> items) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(color: Colors.grey[300], thickness: 1, height: 16),
            ...items.map((item) {
              double quantity = (item['Quantite'] is num)
                  ? (item['Quantite'] as num).toDouble()
                  : 0.0;
              int grams = (quantity * 1000).toInt();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item['Legume'],
                          style: TextStyle(fontSize: 16)),
                    ),
                    Text("$grams g", style: TextStyle(fontSize: 16)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Construit la section d'affichage de la composition des paniers
  Widget _buildCompositionSection(Map<String, dynamic> data) {
    List<dynamic> petitPanier = data['petitPanier'] ?? [];
    List<dynamic> moyenPanier = data['moyenPanier'] ?? [];
    List<dynamic> grandPanier = data['grandPanier'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasketCard("Petit Panier", petitPanier),
        _buildBasketCard("Moyen Panier", moyenPanier),
        _buildBasketCard("Grand Panier", grandPanier),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la Livraison'),
        backgroundColor: Color(0xFF388E3C),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations générales de la livraison
            Text(widget.delivery['delivery'] ?? "Livraison inconnue",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Text("Status: ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text(widget.delivery['status'] ?? "Inconnu",
                    style: TextStyle(
                      fontSize: 18,
                      color: (widget.delivery['status'] ?? "") == "Livré"
                          ? Colors.green
                          : Colors.orange,
                    )),
              ],
            ),
            SizedBox(height: 4),
            Text("Date: ${widget.delivery['timestamp'] ?? ""}",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 24),
            // Section "Contenu de la livraison" (autres informations déjà présentes)
            Text("Contenu de la livraison au dépôt",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            (widget.delivery['paniers'] != null &&
                    widget.delivery['paniers'].isNotEmpty)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (widget.delivery['paniers'] as List<dynamic>)
                        .map((panier) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text("${panier['nom']}: ${panier['quantite']}",
                            style: TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                  )
                : Text("Aucun détail de panier disponible.",
                    style: TextStyle(fontSize: 16)),
            SizedBox(height: 24),
            // Section "Composition des paniers" récupérée via l'API
            Text("Composition des paniers",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            isLoadingBasket
                ? Center(child: CircularProgressIndicator())
                : basketData == null
                    ? Text("Erreur lors du chargement de la composition.",
                        style: TextStyle(fontSize: 16))
                    : _buildCompositionSection(basketData!),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 32, vertical: 12), backgroundColor: Color(0xFF388E3C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Retour", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
