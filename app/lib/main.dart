import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tbchessapp/pages/account.dart';
import 'package:tbchessapp/pages/registration.dart';
import 'package:tbchessapp/pages/login.dart';
import 'package:tbchessapp/pages/login_email.dart';
import 'package:tbchessapp/pages/login_otp.dart';
import 'package:tbchessapp/pages/events.dart';
import 'package:tbchessapp/pages/event_details.dart';
import 'package:tbchessapp/pages/leaderboard.dart';
import 'package:tbchessapp/pages/clock.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tbchessapp/config.dart';
import 'package:tbchessapp/utils/push.dart';

late final SharedPreferences prefs;
late final AsyncAuthStore store;
late final PocketBase pb;

Future<void> main() async {
  prefs = await SharedPreferences.getInstance();

  store = AsyncAuthStore(
    save:    (String data) async => prefs.setString('pb_auth', data),
    initial: prefs.getString('pb_auth'),
  );

  final c = getConfig();
  pb = PocketBase(c['PB_URL'], authStore: store);

  await registerPushWorker();
  
  // await pb.collection('users').authRefresh();

  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/events' //pb.authStore.isValid ? '/events' : '/registration',
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/login_email',
      builder: (context, state) => const LoginEmailPage(),
    ),
    GoRoute(
      path: '/login_otp/:optId',
      builder: (context, state){
        final optId = state.pathParameters['optId']!;
        return LoginOTPPage(optId);
      }
    ),
    GoRoute(
      path: '/registration',
      builder: (context, state) => const RegistrationPage(),
    ),
    GoRoute(
      path: '/events',
      builder: (context, state) => const EventsPage(),
    ),
    GoRoute(
      path: '/event/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;

        // Handle invites
        if (state.uri.queryParameters.isNotEmpty) {
          final invite = state.uri.queryParameters['invite'] ?? '';
          if (invite.isNotEmpty && !pb.authStore.isValid){
            context.setNextPage("/event/$eventId");
            context.setInvite(invite);
          }
        }

        return EventDetailsPage(eventId);
      },
    ),

    GoRoute(
      path: '/leaderboard/:venueId',
      builder: (context, state) {
        final venueId = state.pathParameters['venueId']!;
        return LeaderBoardPage(venueId);
      },
    ),

    GoRoute(
      path: '/clock/:time',
      builder: (context, state){
        return ClockPage(time: state.pathParameters['time']!);
      },
    ),
  ],
);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TB Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: EdgeInsets.all(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            padding: EdgeInsets.all(16),
            textStyle: TextStyle(fontSize: 16)
          ),
        ),
        textTheme: ThemeData.dark().textTheme.merge(TextTheme(
          displayLarge: TextStyle(fontSize: 72.0),
          displayMedium: TextStyle(fontSize: 45.0),
          displaySmall: TextStyle(fontSize: 36.0),
          headlineLarge: TextStyle(fontSize: 32.0),
          headlineMedium: TextStyle(fontSize: 28.0),
          headlineSmall: TextStyle(fontSize: 24.0),
          titleLarge: TextStyle(fontSize: 22.0),
          titleMedium: TextStyle(fontSize: 18.0),
          titleSmall: TextStyle(fontSize: 16.0),
          bodyLarge: TextStyle(fontSize: 18.0),
          bodyMedium: TextStyle(fontSize: 16.0),
          bodySmall: TextStyle(fontSize: 14.0),
          labelLarge: TextStyle(fontSize: 14.0),
          labelMedium: TextStyle(fontSize: 12.0),
          labelSmall: TextStyle(fontSize: 10.0),
        ))
      ),
      routerConfig: _router,
    );
  }
}

String _nextPage = "";
String _invite = "";
bool _pageLoadRedirected = false;
List<String> _routesStack = [];

extension ContextExtension on BuildContext {

  void setInvite(String invite){
    _invite = invite;
  }

  String getInvite(){
    return _invite;
  }

  void setNextPage(String next){
    _nextPage = next;
  }

  String getNextPage(){
    return _nextPage;
  }

  void setPageLoadRedirected(){
    _pageLoadRedirected = true;
  }

  void clearPageLoadRedirected(){
    _pageLoadRedirected = false;
  }

  bool getPageLoadRedirected(){
    return _pageLoadRedirected;
  }

  goAuthPage(){
    if ((prefs.getString("lastEmailLogin") ?? "").isEmpty){
      go("/registration");
    }else{
      go("/login");
    }
  }

  goPush(String location){
    String? current = GoRouterState.of(this).uri.toString();
    if (current != null) _routesStack.add(current);
    go(location);
  }

  goBackOrTo(String fallback){
    if (_routesStack.isNotEmpty) {
      final previousRoute = _routesStack.removeLast();
      go(previousRoute);
    } else {
      go(fallback);
    }
  }

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Colors.white
      ),
    );
  }

  Future<void> showMessageBox(String message, {String? title}) async {
    await showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> showConfirmDialog(String message, {String? title, String? cancelText, String? confirmText}) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(cancelText ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(confirmText ?? 'Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> showNetworkError(ClientException error, {String? title}) async {
    String msg = '';
    final response = error.response as Map;

    if (title == null && response.containsKey('message')) {
      final message = response['message'];
      if (message is String) {
        msg = '$message\n\n';
      }
    }else if (title != null){
      msg = '$title\n\n';
    }
    
    if (response.containsKey('data')) {
      final fields = response['data'];
      if (fields is Map) {
        final messages = <String>[];
        fields.forEach((field, attrs) {
          if (attrs is Map && attrs.containsKey('message')) {
            final m = attrs['message'];
            if (m is String){
              messages.add('$field: $m');
            }
          }
        });
        if (messages.isNotEmpty) {
          msg += messages.join('\n');
        }
      }
    }
    if (msg.isEmpty) msg = error.toString();
    await showMessageBox(msg);
  }
}
