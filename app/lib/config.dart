
import 'package:flutter/foundation.dart';

Map<String, dynamic> getConfig(){
  if (kDebugMode){
    return {
      'APP_URL': 'http://localhost',
      'PB_URL': 'http://192.168.2.253:4090'
    };
  }else{
    // Production
    return {
      'APP_URL': 'https://app.tbchess.org',
      'PB_URL': 'https://app.tbchess.org'
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