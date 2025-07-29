import 'package:pocketbase/pocketbase.dart';

String getUsername(RecordModel user){
  String name = user.data['name'].toString();
  if (name.isNotEmpty){
    return name;
  }else{
    return "Anonymous";
  }
}