import 'package:flutter/material.dart';
import 'package:tbchessapp/utils/date.dart';

class EventDateTime extends StatelessWidget  {
  final String eventDate;
  final double spacing;

  const EventDateTime(this.eventDate, {this.spacing = 0, super.key});

   @override
  Widget build(BuildContext context) {
    bool wideScreen = MediaQuery.of(context).size.width >= 420;


    DateTime? eventDate = parseDateString(this.eventDate);
    String dateDisplay = '';
    String timeDisplay = '';
    if (eventDate != null){
      dateDisplay = "${getWeekday(eventDate, short: !wideScreen)}, ${getMonthShort(eventDate)} ${eventDate.day}";
      timeDisplay = "${eventDate.hour > 12 ? eventDate.hour - 12 : (eventDate.hour == 0 ? 12 : eventDate.hour)}:${eventDate.minute.toString().padLeft(2, '0')} ${eventDate.hour >= 12 ? 'PM' : 'AM'}";
    }

    if (dateDisplay.isNotEmpty && timeDisplay.isNotEmpty){
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 4),
            Text(dateDisplay),
          ],),
          SizedBox(height: spacing),
          Row(children: [
            const Icon(Icons.access_time, size: 16),
            const SizedBox(width: 4),
            Text(timeDisplay),
          ],)
        ],
      );
    }else{
      return Column();
    }
  }
}