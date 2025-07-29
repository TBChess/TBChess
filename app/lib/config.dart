
import 'package:flutter/foundation.dart';

Map<String, dynamic> getConfig(){
  String domain = const String.fromEnvironment('DOMAIN', defaultValue: 'localhost');
  bool production = const String.fromEnvironment("PRODUCTION", defaultValue: 'dev') == 'production';

  if (production){
    return {
      'APP_URL': 'https://$domain',
      'PB_URL': 'https://$domain'
    };
  }else{
    return {
      'APP_URL': 'http://$domain:4090',
      'PB_URL': 'http://$domain:4090'
    };
  }
}

String assetImagePath(String p){
  if (kDebugMode){
    return p;
  }else{
    return "assets/$p";
  }
}