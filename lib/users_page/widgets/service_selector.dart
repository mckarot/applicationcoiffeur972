import 'package:flutter/material.dart';
import 'package:soifapp/models/haircut_service.dart';

class ServiceSelector extends StatelessWidget {
  final HaircutService? selectedService;
  final VoidCallback onTap;

  const ServiceSelector({
    super.key,
    this.selectedService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('2. Choisissez un service :',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedService == null
                        ? 'Cliquez pour choisir un service'
                        : '${selectedService!.name} (${selectedService!.duration.inMinutes} min)',
                    style: TextStyle(
                      color: selectedService == null
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.7)
                          : Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
