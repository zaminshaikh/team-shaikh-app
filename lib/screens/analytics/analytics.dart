import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agq_app/components/assets_structure_section.dart';
import 'package:agq_app/components/custom_bottom_navigation_bar.dart';
import 'package:agq_app/components/progress_indicator.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/screens/analytics/components/analytics_app_bar.dart';
import 'package:agq_app/screens/analytics/components/line_chart.dart';


class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  AnalyticsPageState createState() => AnalyticsPageState();
}

class AnalyticsPageState extends State<AnalyticsPage> {
  Client? client;
  late List<Client> allClients;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    client = Provider.of<Client?>(context);
    // Build a combined list of the main client plus any connected clients.
    allClients = [];
    if (client != null) {
      allClients.add(client!);
      if (client!.connectedUsers != null) {
        for (final c in client!.connectedUsers!) {
          if (c != null) {
            allClients.add(c);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (client == null) {
      return const CustomProgressIndicatorPage();
    }

    final List<Widget> fundCharts = [];
    final funds = client?.assets?.funds ?? {};

    funds.forEach((fundName, fund) {
      final totalAssets =
          fund.assets.values.fold(0.0, (sum, asset) => sum + asset.amount);
      if (totalAssets > 0) {
        fundCharts.add(
          Column(
            children: [
              AssetsStructureSection(
                client: client!,
                fundName: fundName,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              AnalyticsAppBar(client: client!),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // Line chart section
                      LineChartSection(client: client!),
                      // Display the fund-based pie charts
                      ...fundCharts,
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigationBar(
              currentItem: NavigationItem.analytics,
            ),
          ),
        ],
      ),
    );
  }
}