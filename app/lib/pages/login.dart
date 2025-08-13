import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tbchessapp/config.dart';
import 'package:web/web.dart' as web;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _loginWithGoogle() async {
    try {
      // on iOS, you cannot launch new windows from async
      web.Window? w;

      if (kIsWeb){
        w = web.window.open("", "_blank");
        if (mounted && w == null){
          context.showMessageBox("Cannot login with Google (auth popup blocked)");
          return;
        }
      }

      await pb.collection('users').authWithOAuth2('google', (url) async {
        // TODO: or use something like flutter_custom_tabs?

        if (kIsWeb){
          w!.location.href = url.toString();
        }else{
          await launchUrl(url);
        }

      });

      if (pb.authStore.isValid && mounted){
        context.goNextPageOrTo("/events");
      }else{
        if (mounted){
          context.showMessageBox("Login failed");
        }
      }
    } on ClientException catch (error){
      if (mounted){
        context.showNetworkError(error, title: "Login failed");
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome, contender'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric( horizontal: 16),
        children: [
          SizedBox(
            height: 250,
            child: Center(
              child:  SvgPicture.asset(
                assetImagePath('images/logo.svg'),
                semanticsLabel: 'TB Chess Logo',
                allowDrawingOutsideViewBox: true,
                height: 100,
              )
            ),
          ),
          
          const Text('Glory awaits. Login with your account to join a battle:', textAlign: TextAlign.center,),
          const SizedBox(height: 18),
          
          const SizedBox(height: 18),
            Column(mainAxisAlignment: MainAxisAlignment.center, children:[ 
            ElevatedButton(
              onPressed: _isLoading ? null : _loginWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  assetImagePath('images/google.svg'),
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 12),
                Container(
                  height: 20,
                  width: 2,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(_isLoading ? 'Logging in ...' : 'Continue with Google'),
              ],
              ),
              ),
            ),

            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : () => {
                context.go((prefs.getString("lastEmailLogin") ?? "").isEmpty ? "/registration" : "/login_email")
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.email, size: 20),
                const SizedBox(width: 12),
                Container(
                  height: 20,
                  width: 2,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text('Continue with E-mail'),
              ],
              ),
              ),
            ),
            const SizedBox(height: 48),

            TextButton(
              onPressed: () async {
                final Uri url = Uri.parse('https://tbchess.org/privacy');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              child: const Text('Privacy Policy'),
            ),
            ],
          ),

        ],
      ),
    );
  }
}
