import 'package:agq_app/database/models/graph_point_model.dart';

/// Represents a collection of GraphPoints associated with a specific account.
class Graph {
  /// The account name associated with this graph.
  final String account;

  /// The list of GraphPoints for this account.
  final List<GraphPoint> graphPoints;

  /// Creates a [Graph] instance with the given account and list of graph points.
  Graph({
    required this.account,
    required this.graphPoints,
  });

    /// Converts the [Graph] instance into a map for serialization.
  Map<String, dynamic> toMap() => {
    'account': account,
    'graphPoints': graphPoints.map((point) => point.toMap()).toList(),
  };
}
