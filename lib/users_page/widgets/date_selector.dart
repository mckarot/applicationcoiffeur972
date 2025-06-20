import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final Function(BuildContext) onPickDateTap;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPickDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1. Choisissez une date :',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 15),
        _buildHorizontalCalendar(context),
        const SizedBox(height: 10),
        Center(
          child: ElevatedButton.icon(
            icon: Icon(Icons.calendar_today,
                color: Theme.of(context).colorScheme.onPrimary),
            label: Text(
              selectedDate == null
                  ? 'Sélectionner une date'
                  : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => onPickDateTap(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalCalendar(BuildContext context) {
    List<Widget> dateWidgets = [];
    DateTime today = DateTime.now();

    for (int i = 0; i < 14; i++) {
      DateTime date = today.add(Duration(days: i));
      bool isSelected = selectedDate != null &&
          date.year == selectedDate!.year &&
          date.month == selectedDate!.month &&
          date.day == selectedDate!.day;

      dateWidgets.add(
        GestureDetector(
          onTap: () => onDateSelected(date),
          child: Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  DateFormat.E('fr_FR').format(date).substring(0, 3),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: dateWidgets,
      ),
    );
  }
}
