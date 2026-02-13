// ignore_for_file: library_private_types_in_public_api, unused_element, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agq_app/components/progress_indicator.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/database/models/notification_model.dart';
import 'package:agq_app/screens/notifications/components/mark_all_read_button.dart';
import 'package:agq_app/screens/notifications/components/notification_card.dart';
import 'package:agq_app/screens/notifications/components/notifications_app_bar.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  Client? client;  
  List<Notif> notifications = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    client = Provider.of<Client?>(context);
  }

  @override
  Widget build(BuildContext context){
    if (client == null) {
      return const Center(
        child: CustomProgressIndicatorPage(),
      );
    }
    notifications = List.from(client!.notifications!);
    if (client!.connectedUsers != null && client!.connectedUsers!.isNotEmpty) {
      final connectedUserNotifications = client!.connectedUsers!
        .where((user) => user != null)
        .expand((user) => user!.notifications ?? [].cast<Notif>());
      notifications.addAll(connectedUserNotifications);
    }
    notifications.sort((a, b) => b.time.compareTo(a.time));
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              const NotificationsAppBar(),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    // Get the notification data
                    Notif notification = notifications[index];
                    // Get the previous notification date
                    // DateTime previousNotificationDate = index > 0 ? (notifications[index - 1].time): DateTime(0);
                    // Check if the current notification is on a different day than the previous one
                    return NotificationCard(notification: notification, client: client!);
                  },
                  childCount: notifications.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 150),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: MarkAllAsReadButton(client: client!, 
        onRefresh: () { setState(() {}); },),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}