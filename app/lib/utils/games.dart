import 'package:pocketbase/pocketbase.dart';

String getUserColor(RecordModel game, String userId){
  if (game.getStringValue("white") == userId) return "white";
  if (game.getStringValue("black") == userId) return "black";
  return "";
}