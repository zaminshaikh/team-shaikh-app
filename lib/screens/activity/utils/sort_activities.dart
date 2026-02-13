// Implement sorting on activities based on the user's selection (defaulted to _sorting = 'new-to-old')
import 'dart:developer';

import 'package:agq_app/database/models/activity_model.dart';

enum SortOrder { newToOld, oldToNew, lowToHigh, highToLow }

void sortActivities(List<Activity> activities, SortOrder order) {
  try {
    switch (order) {
      case SortOrder.newToOld:
        activities.sort((a, b) => b.time.compareTo(a.time));
        break;
      case SortOrder.oldToNew:
        activities.sort((a, b) => a.time.compareTo(b.time));
        break;
      case SortOrder.lowToHigh:
        activities.sort((a, b) => a.amount.compareTo(b.amount.toDouble()));
        break;
      case SortOrder.highToLow:
        activities.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      default:
        throw ArgumentError('Invalid sort order: $order');
    }
  } catch (e) {
    if (e is TypeError) {
      // Handle TypeError here (usually casting error)
      log('activity.dart: Caught TypeError: $e');
    } else {
      // Handle other exceptions here
      log('activity.dart: Caught Exception: $e');
    }
  }
}