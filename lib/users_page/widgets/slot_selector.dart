import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soifapp/models/haircut_service.dart';

class SlotSelector extends StatelessWidget {
  final List<String> availableSlots;
  final String? selectedSlot;
  final Function(String?) onSlotSelected;
  final HaircutService? selectedService; // Nécessaire pour afficher la durée
  final bool isLoading;
  final String? error;

  const SlotSelector({
    super.key,
    required this.availableSlots,
    this.selectedSlot,
    required this.onSlotSelected,
    this.selectedService,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ));
    }

    if (availableSlots.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Aucun créneau disponible pour cette sélection.'),
      ));
    }

    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: availableSlots.map((slotStartTime) {
        final isSelected = selectedSlot == slotStartTime;
        String displaySlot = slotStartTime;
        if (selectedService != null) {
          try {
            final format = DateFormat.Hm('fr_FR');
            final start = format.parse(slotStartTime);
            final end = start.add(selectedService!.duration);
            displaySlot = '${format.format(start)} - ${format.format(end)}';
          } catch (e) {/* Garder slotStartTime si erreur */}
        }
        return ChoiceChip(
          label: Text(displaySlot,
              style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary)),
          selected: isSelected,
          selectedColor: Theme.of(context).colorScheme.primary,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant)),
          onSelected: (bool selected) =>
              onSlotSelected(selected ? slotStartTime : null),
        );
      }).toList(),
    );
  }
}
