import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agq_app/database/models/graph_model.dart';
import 'package:agq_app/database/models/graph_point_model.dart';
import 'package:agq_app/database/models/assets_model.dart';
import 'package:agq_app/database/models/notification_model.dart';
import 'package:agq_app/database/models/activity_model.dart';

/// Represents a client in the application.
///
/// The `Client` class encapsulates all the relevant data for a client, including personal information,
/// financial data, notifications, activities, assets, and connected users.
class Client {
  /// Client ID (CID), a unique identifier for the client.
  final String cid;

  /// User ID (UID) from Firebase Authentication.
  final String uid;

  /// Client's first name.
  final String firstName;

  /// Client's last name.
  final String lastName;

  /// Company name associated with the client, if any.
  final String? companyName;

  /// Client's address.
  final String? address;

  /// Client's date of birth.
  final DateTime? dob;

  /// Client's phone number.
  final String? phoneNumber;

  /// Email used in the app for authentication.
  final String? appEmail;

  /// Initial email associated with the client.
  final String? initEmail;

  /// Date of the client's first deposit.
  final DateTime? firstDepositDate;

  /// List of beneficiaries associated with the client.
  final List<String>? beneficiaries;

  /// List of connected users (e.g., family members).
  final List<Client?>? connectedUsers;

  /// Total assets value for the client.
  final double? totalAssets;

  /// Number of unread notifications.
  final int? numNotifsUnread;

  /// List of recipients associated with the client's activities.
  final List<String>? recipients;

  /// List of notifications for the client.
  List<Notif>? notifications;

  /// List of activities (transactions) for the client.
  List<Activity>? activities;

  /// List of graph points for displaying financial data over time.
  List<Graph>? graphs;

  /// Financial assets associated with the client.
  final Assets? assets;

  /// Creates a [Client] instance with the given parameters.
  Client({
    required this.cid,
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.appEmail,
    this.totalAssets,
    this.companyName,
    this.address,
    this.dob,
    this.phoneNumber,
    this.initEmail,
    this.firstDepositDate,
    this.beneficiaries,
    this.numNotifsUnread,
    this.connectedUsers,
    this.notifications,
    this.activities,
    this.graphs,
    this.assets,
    this.recipients,
  });

  /// Creates a [Client] instance from a [Map] representation.
  ///
  /// [data] is a map containing client data, typically from Firestore.
  /// Additional parameters can be provided for activities, assets, notifications, etc.
  factory Client.fromMap(
    Map<String, dynamic>? data, {
    String? cid,
    List<Activity>? activities,
    Assets? assets,
    List<Notif>? notifications,
    List<GraphPoint>? graphPoints,
    List<Client?>? connectedUsers,
  }) {
    if (data == null) {
      return Client.empty();
    }

        // Group GraphPoints by account
    Map<String, List<GraphPoint>> graphPointsByAccount = {};

    if (graphPoints != null) {
      for (var point in graphPoints) {
        final accountKey = point.account ?? 'Unknown';
        graphPointsByAccount.putIfAbsent(accountKey, () => []).add(point);
      }
    }

    // Create Graph objects
    List<Graph> graphs = graphPointsByAccount.entries.map((entry) {
      // Sort graph points by time if necessary
      entry.value.sort((a, b) => a.time.compareTo(b.time));
      return Graph(account: entry.key, graphPoints: entry.value);
    }).toList();

    final unreadOwn = (notifications ?? [])
        .where((notif) => !notif.isRead)
        .length;

    // ignore: avoid_types_as_parameter_names
    final unreadConnected = (connectedUsers ?? []).fold<int>(0, (sum, c) => sum + ((c?.notifications ?? [])
          .where((notif) => !notif.isRead)
          .length));

    return Client(
      cid: data['cid'] ?? cid ?? '',
      uid: data['uid'] ?? '',
      firstName: data['name']?['first'] ?? '',
      lastName: data['name']?['last'] ?? '',
      companyName: data['name']?['company'] ?? '',
      address: data['address'] ?? '',
      dob: (data['dob'] as Timestamp?)?.toDate(),
      phoneNumber: data['phoneNumber'] ?? '',
      appEmail: data['appEmail'] ?? '',
      initEmail: data['initEmail'] ?? '',
      firstDepositDate: (data['firstDepositDate'] as Timestamp?)?.toDate(),
      beneficiaries: List<String>.from(data['beneficiaries'] ?? []),
      numNotifsUnread: unreadOwn + unreadConnected,
      recipients: activities
          ?.map((activity) => activity.recipient)
          .toSet()
          .toList(),
      connectedUsers: connectedUsers ?? [],
      activities: activities ?? [],
      graphs: graphs,
      assets: assets,
      notifications: notifications ?? [],
    );
  }

  /// Creates an empty [Client] instance with default values.
  Client.empty()
      : cid = '',
        uid = '',
        firstName = '',
        lastName = '',
        companyName = '',
        address = '',
        dob = null,
        phoneNumber = '',
        appEmail = '',
        initEmail = '',
        firstDepositDate = null,
        beneficiaries = [],
        connectedUsers = [],
        totalAssets = 0.0,
        numNotifsUnread = 0,
        recipients = [],
        notifications = [],
        activities = [],
        graphs = [],
        assets = Assets.empty();

  /// Converts the [Client] instance into a [Map] representation.
  ///
  /// Useful for encoding data to store in Firestore.
  Map<String, dynamic> toMap() => {
        'cid': cid,
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'companyName': companyName,
        'address': address,
        'dob': dob,
        'phoneNumber': phoneNumber,
        'appEmail': appEmail,
        'initEmail': initEmail,
        'firstDepositDate': firstDepositDate,
        'beneficiaries': beneficiaries,
        'connectedUsers': connectedUsers,
        'totalAssets': totalAssets,
        'activities': activities?.map((e) => e.toMap()).toList(),
        'graphPoints': graphs?.map((e) => e.toMap()).toList(),
        'assets': assets?.toMap(),
      };
}
