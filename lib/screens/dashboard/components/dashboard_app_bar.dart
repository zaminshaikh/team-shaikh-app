import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:agq_app/screens/notifications/notifications.dart';
import 'package:agq_app/database/models/client_model.dart';

class DashboardAppBar extends StatelessWidget {
  final Client client;

  const DashboardAppBar({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    String welcomeMessage;
    String fullName = '${client.firstName} ${client.lastName}';
    if (fullName.length > 20) {
      String shorterName = client.firstName.length <= client.lastName.length
          ? client.firstName
          : client.lastName;
      welcomeMessage = 'Welcome, $shorterName!';
    } else {
      welcomeMessage = 'Welcome, $fullName!';
    }
    
    return SliverAppBar(
      backgroundColor: const Color.fromARGB(255, 30, 41, 59),
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      expandedHeight: 0,
      snap: false,
      floating: true,
      pinned: true,
      flexibleSpace: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    welcomeMessage,
                    style: const TextStyle(
                      fontSize: 23,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Client ID: ${client.cid}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 5.0, bottom: 5.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
            child: Container(
              color: const Color.fromRGBO(239, 232, 232, 0),
              padding: const EdgeInsets.all(10.0),
              child: ClipRect(
                child: Stack(
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.transparent,
                              width: 0.3,
                            ),
                            shape: BoxShape.rectangle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/bell.svg',
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn),
                              height: 32,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 5,
                          child: (client.numNotifsUnread ?? 0) > 0
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF267DB5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '${client.numNotifsUnread}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Titillium Web',
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Container(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}