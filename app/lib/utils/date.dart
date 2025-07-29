
String getWeekday(DateTime dt, { bool short = false}){
  const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  if (short) return weekdays[dt.weekday - 1].substring(0, 3);
  return weekdays[dt.weekday - 1];
}

String getMonthShort(DateTime dt){
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[dt.month - 1];
}

DateTime? parseDateString(String dateTime){
    DateTime? d;
    try {
      d = DateTime.parse(dateTime).toLocal();
    } catch (_) {}
    return d;
}