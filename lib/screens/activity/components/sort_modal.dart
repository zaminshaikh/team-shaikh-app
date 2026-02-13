import 'package:flutter/material.dart';
import 'package:agq_app/screens/activity/utils/sort_activities.dart';
import 'package:agq_app/screens/utils/resources.dart';

/// A modal widget for selecting sort options.
class ActivitySortModal extends StatelessWidget {
  final SortOrder currentOrder;
  final Function(SortOrder) onSelect;

  const ActivitySortModal({
    super.key,
    required this.currentOrder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        child: Container(
          color: AppColors.defaultBlueGray800,
          child: Column(
            children: [
              const SizedBox(height: 20.0),
              const Padding(
                padding: EdgeInsets.fromLTRB(20.0, 0, 0, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sort By',
                    style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Titillium Web'),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              _buildSortOption(
                  context, 'Date: New to Old (Default)', SortOrder.newToOld),
              _buildSortOption(context, 'Date: Old to New', SortOrder.oldToNew),
              _buildSortOption(
                  context, 'Amount: Low to High', SortOrder.lowToHigh),
              _buildSortOption(
                  context, 'Amount: High to Low', SortOrder.highToLow),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );

  /// Builds an individual sort option.
  Widget _buildSortOption(BuildContext context, String title, SortOrder value) => ListTile(
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: currentOrder == value
              ? AppColors.defaultBlue500
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          title,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              fontFamily: 'Titillium Web'),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onSelect(value);
      },
    );
}
