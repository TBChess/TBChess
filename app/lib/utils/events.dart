import 'package:tbchessapp/utils/date.dart';

String getEventTitle(Map<String, dynamic> event){
  DateTime? d = parseDateString(event['event_date']);
  String speed = "";
  String timeControl = "";
  if (event['time_control'] != null){
    timeControl = event['time_control'].toString();
  }
  if (timeControl.startsWith('5') || timeControl.startsWith('10')){
    speed = "Blitz ";
  }else if (timeControl.startsWith('15') || timeControl.startsWith('30')){
    speed = "Rapid ";
  }

  if (d == null){
    return "${speed}Chess Event ${event['id']}";
  }else{
    return "${getWeekday(d)} ${speed}Chess";
  }
}

String getVenueAddress(Map<String, dynamic> venue){
  if (venue.containsKey('address')){
    return venue['address'].toString().replaceFirst(", ", "\n");
  }
  return ""; 
}