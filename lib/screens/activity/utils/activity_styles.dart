// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:agq_app/screens/activity/utils/sort_activities.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/database/models/activity_model.dart';
import 'package:agq_app/screens/utils/utilities.dart';

// Get Activity Type Text
String getActivityType(Activity activity) {
  switch (activity.type) {
    case 'income':
    case 'profit':
      return 'Profit';
    case 'deposit':
      return 'Deposit';
    case 'withdrawal':
      return 'Withdrawal';
    case 'pending':
      return 'Pending Withdrawal';
    default:
      return 'Error';
  }
}

// Get color based on activity type
Color getActivityColor(String type) {
  switch (type) {
    case 'deposit':
      return AppColors.defaultGreen400;
    case 'withdrawal':
      return AppColors.defaultRed400;
    case 'pending':
      return AppColors.defaultYellow400;
    case 'income':
    case 'profit':
      return AppColors.defaultBlue300;
    default:
      return Colors.white;
  }
}

// Get underlay color based on activity type
Color getUnderlayColor(String type) {
  switch (type) {
    case 'deposit':
      return const Color.fromARGB(255, 21, 52, 57);
    case 'withdrawal':
      return const Color.fromARGB(255, 41, 25, 28);
    case 'pending':
    case 'income':
    case 'profit':
      return const Color.fromARGB(255, 24, 46, 68);
    default:
      return Colors.white;
  }
}

// Get the icon for each activity type
Widget getActivityIcon(String type, {double size = 50.0}) {
  switch (type) {
    case 'deposit':
      return SvgPicture.asset(
        'assets/icons/deposit.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    case 'withdrawal':
      return SvgPicture.asset(
        'assets/icons/withdrawal.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    case 'pending':
      return SvgPicture.asset(
        'assets/icons/pending_withdrawal.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    case 'income':
    case 'profit':
      return SvgPicture.asset(
        
        'assets/icons/variable_income.svg',
        color: getActivityColor(type),
        height: size,
        width: size,
      );
    default:
      return Icon(
        Icons.circle,
        color: Colors.transparent,
        size: size,
      );
  }
}

// Helper functions at the top
String getActivityDescription(Activity activity) {
  String action;
  switch (activity.type) {
    case 'deposit':
      action = 'Deposit to your investment at';
      break;
    case 'withdrawal':
      action = 'Withdrawal from your investment at';
      break;
    case 'pending':
      action = 'Pending withdrawal from your investment at';
      break;
    case 'income':
    case 'profit':
      action = 'Profit to your investment at';
      break;
    default:
      action = '';
  }
  return '$action ${activity.fund}';
}

/// Generates the date button text based on the selected date range.
String getDateButtonText(DateTime startDate, DateTime endDate) {
  DateTime startOfRange = DateTime(1900, 1, 1);
  DateTime today = DateTime.now();
  DateTime todayDate = DateTime(today.year, today.month, today.day);

  bool isAllTime = startDate == startOfRange &&
      (endDate == todayDate || endDate.isAfter(todayDate));
  if (isAllTime) {
    return 'All Time';
  } else {
    String formattedStartDate =
        '${startDate.month}/${startDate.day}/${startDate.year}';
    String formattedEndDate =
        '${endDate.month}/${endDate.day}/${endDate.year}';
    return '$formattedStartDate - $formattedEndDate';
  }
}

/// Generates the type button text based on the selected types.
String getTypeButtonText(List<String> typeFilter) {
  List<String> allTypes = ['profit', 'deposit', 'withdrawal'];

  if (allTypes.every((type) => typeFilter.contains(type))) {
    return 'All Types';
  } else if (typeFilter.isEmpty) {
    return 'No Types Selected';
  } else {
    List<String> displayTypes = typeFilter
        .where((type) => type != 'income')
        .map((type) => toTitleCase(type))
        .toList();
    return displayTypes.join(', ');
  }
}

/// Generates the recipients button text based on the selected recipients.
String getRecipientsButtonText(
    List<String> recipientsFilter, List<String> allRecipients) {
  if (allRecipients.every((recipient) => recipientsFilter.contains(recipient))) {
    return 'All Recipients';
  } else if (recipientsFilter.isEmpty) {
    return 'No Recipients Selected';
  } else {
    return recipientsFilter.join(', ');
  }
}

/// Returns a string representation of the sort order.
String getSortOrderText(SortOrder order) {
  switch (order) {
    case SortOrder.newToOld:
      return 'Date: New to Old';
    case SortOrder.oldToNew:
      return 'Date: Old to New';
    case SortOrder.lowToHigh:
      return 'Amount: Low to High';
    case SortOrder.highToLow:
      return 'Amount: High to Low';
    default:
      return '';
  }
}
