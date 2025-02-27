import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    // Rafraîchissement toutes les 5 secondes
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
    //final url = Uri.parse("http://192.168.1.24:5000/notifications");
    final url = Uri.parse("http://127.0.0.1:5000/notifications");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          notifications = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("Erreur lors de la récupération des notifications: ${response.body}");
        setState(() { isLoading = false; });
      }
    } catch (e) {
      print("Erreur lors de la requête des notifications: $e");
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
        title: Text('Notifications'),
        backgroundColor: Color(0xFF388E3C),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: notifications.isEmpty
                  ? ListView(
                      children: [Center(child: Text("Aucune notification pour le moment."))],
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.0),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        var notification = notifications[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.notifications, color: Color(0xFF388E3C)),
                            title: Text("${notification['delivery']} - ${notification['status']}"),
                            subtitle: Text(notification['timestamp']),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
