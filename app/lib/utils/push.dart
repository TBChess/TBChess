import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:tbchessapp/main.dart';


web.ServiceWorkerRegistration? _serviceWorker;
bool _webPushDenied = false;

bool supportsPush(){
  if (!kIsWeb){
    return false; // TODO: mobile
  }

  if (!web.window.navigator.hasProperty("serviceWorker".toJS).toDart) {
    // Service Worker isn't supported on this browser, disable or hide UI.
    return false;
  }

  if (!web.window.hasProperty("PushManager".toJS).toDart) {
    // Push isn't supported on this browser, disable or hide UI.
    return false;
  }

  return true;
}

bool supportsPushNotifications(){
  bool sp = supportsPush();
  if (!sp) return false;
  if (_serviceWorker == null) return false;
  return _serviceWorker!.hasProperty("showNotification".toJS).toDart;
}

bool deniedPushNotifications(){
  return _webPushDenied;
}

Future<void> registerPushWorker() async{
  if (kIsWeb && supportsPush()){
    try{
      _serviceWorker = await web.window.navigator.serviceWorker.register("/service-worker.js".toJS).toDart;
      if (_serviceWorker == null) return;

      web.PushSubscription? sub = await _serviceWorker!.pushManager.getSubscription().toDart;
      if (sub == null) return;
    }catch(e){
      debugPrint("Cannot register service worker: ${e.toString()}");
      _webPushDenied = true; // Assume
    }
  }
}

Future<void> requestPushPermission() async{
  final permission = await web.Notification.requestPermission().toDart;
  if (permission.toDart != 'granted') {
    throw Exception("Permission denied. Check your device settings to enable notifications.");
  }
}

Future<web.PushSubscription> registerPush() async{
  if (_serviceWorker == null) throw Exception("Cannot register push (service worker is null)");
  await requestPushPermission();
  
  try{
    final res = await pb.send("/api/tbchess/vapid", method: "GET");
    final key = urlBase64ToUint8Array(res['publicKey']);

    final sub = await _serviceWorker!.pushManager.subscribe(
      web.PushSubscriptionOptionsInit(
        userVisibleOnly: true,
        applicationServerKey: key.toJS,
      ),
    ).toDart;
    
    return sub;
  }catch(e){
    throw Exception("Cannot register notification (server keys unavailable)");
  }
}

Future<void> setupWebPush() async{
  if (!pb.authStore.isValid) throw Exception("Session expired. Please log-in again.");

  final sub = await registerPush();
  await pb.collection('users').update(pb.authStore.record!.id, body: {'webpush_sub': sub.toJSON().dartify()!});
}

Future<void> cancelWebPush() async{
  if (!pb.authStore.isValid) throw Exception("Session expired. Please log-in again.");
  if (_serviceWorker == null) throw Exception("Cannot register push (service worker is null)");  

  await pb.collection('users').update(pb.authStore.record!.id, body: {'webpush_sub': null});
  web.PushSubscription? sub = await _serviceWorker!.pushManager.getSubscription().toDart;
  if (sub == null) return;

  sub.unsubscribe();
}

Uint8List urlBase64ToUint8Array(String base64String) {
  // Add padding
  var padding = '=' * ((4 - base64String.length % 4) % 4);
  var base64 = (base64String + padding)
      .replaceAll('-', '+')
      .replaceAll('_', '/');

  // Decode base64 to bytes
  return base64Decode(base64);
}
