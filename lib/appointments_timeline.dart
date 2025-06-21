import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soifapp/users_page/planning_page.dart'; // Ensure Appointment class is accessible
import 'package:timezone/timezone.dart' as tz; // Import timezone

class AppointmentsTimeline extends StatelessWidget {
  final List<Appointment> appointments;
  final tz.Location salonLocation;
  final void Function(Appointment)? onAppointmentTap;

  const AppointmentsTimeline({
    super.key,
    required this.appointments,
    required this.salonLocation,
    this.onAppointmentTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sort appointments by start time
    appointments.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Get current time in salon's timezone
    final now = tz.TZDateTime.now(salonLocation);

    // Use the date from the first appointment to ensure all calculations are for the selected day
    final selectedDay =
        appointments.isNotEmpty ? appointments.first.startTime : now;

    // Check if the selected day is today for the current time line.
    final isSelectedDayToday = tz.TZDateTime(
            salonLocation, selectedDay.year, selectedDay.month, selectedDay.day)
        .isAtSameMomentAs(
            tz.TZDateTime(salonLocation, now.year, now.month, now.day));

    // Define the start and end hours for the timeline
    const int startHour = 8; // Timeline starts at 8 AM
    const int endHour = 20; // Timeline ends at 8 PM (20:00)
    const double hourHeight = 120.0; // Height for each hour slot
    final double totalHeight = (endHour - startHour) * hourHeight;
    final timelineStartDateTime = tz.TZDateTime(salonLocation, selectedDay.year,
        selectedDay.month, selectedDay.day, startHour);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              // --- Hour markers and lines ---
              ...List.generate(endHour - startHour + 1, (index) {
                final hour = startHour + index;
                final hourDateTime = tz.TZDateTime(salonLocation,
                    selectedDay.year, selectedDay.month, selectedDay.day, hour);
                final hourText = DateFormat('HH:00').format(hourDateTime);

                return Positioned(
                  top: (index * hourHeight),
                  left: 0,
                  right: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hourText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(
                              top: 8), // Align with text baseline
                          height: 1,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // --- Appointment Cards ---
              ...appointments.map((appointment) {
                // Calculate top offset from the start of the timeline (startHour)
                final minutesFromStart = appointment.startTime
                    .difference(timelineStartDateTime)
                    .inMinutes;
                final topOffset = (minutesFromStart / 60.0) * hourHeight +
                    8.0; // Add 8.0 to align with the hour line

                // Calculate the height of the appointment block based on its duration
                final blockHeight =
                    (appointment.duration.inMinutes / 60.0) * hourHeight;

                return Positioned(
                  left: 50.0, // Indent appointments from the hour text
                  right: 0,
                  top: topOffset,
                  height: blockHeight.clamp(
                      20.0,
                      totalHeight -
                          topOffset), // Clamp height to not overflow timeline
                  child: GestureDetector(
                    onTap: onAppointmentTap != null
                        ? () => onAppointmentTap!(appointment)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            appointment.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat.Hm('fr_FR').format(appointment.startTime)} - ${DateFormat.Hm('fr_FR').format(appointment.endTime)}',
                            style: TextStyle(
                                fontSize: 12.0, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              // --- Red line for current time ---
              if (isSelectedDayToday &&
                  now.hour >= startHour &&
                  now.hour < endHour)
                Positioned(
                  top:
                      (now.difference(timelineStartDateTime).inMinutes / 60.0) *
                              hourHeight +
                          8.0, // Add 8.0 to align with the hour line
                  left: 50, // Start after the hour text
                  right: 0,
                  child: Container(
                    height: 2.5,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
