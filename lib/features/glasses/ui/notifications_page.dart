import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.local_offer_outlined),
            title: Text('New arrivals this week'),
            subtitle: Text('Check out 8 new 3D-ready frames.'),
          ),
          ListTile(
            leading: Icon(Icons.favorite_outline),
            title: Text('Price drop on your favorites'),
            subtitle: Text('Some saved frames are now on sale.'),
          ),
          ListTile(
            leading: Icon(Icons.tips_and_updates_outlined),
            title: Text('Try-On tip'),
            subtitle: Text('Use good lighting for better face tracking.'),
          ),
        ],
      ),
    );
  }
}
