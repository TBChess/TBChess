import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tbchessapp/config.dart';
import 'dart:convert';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  bool _isLoading = false;
  bool _initialized = false;
  bool _invited = false;
  late final TextEditingController _usernameController = TextEditingController();
  late final TextEditingController _passwordController = TextEditingController();

  Future<void> _register() async {
    if (_usernameController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      if (mounted) {
        context.showMessageBox('Please fill-in all fields');
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Create user account
      final body = <String, dynamic>{
        "email": _usernameController.text.trim(),
        "password": _passwordController.text.trim(),
        "passwordConfirm":  _passwordController.text.trim(),
        "emailVisibility": false
      };

      await pb.collection('users').create(body: body);

      // Automatically sign in the user after successful registration
      await pb.collection('users').authWithPassword(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        _usernameController.clear();
        _passwordController.clear();
        
        if (context.getNextPage().isNotEmpty) {
          context.go(context.getNextPage());
        }else{ 
          context.go("/events");
        }
      }
    } on ClientException catch (error){
      if (mounted){
        context.showNetworkError(error, title: "Registration failed");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkInvite() async {
    String invite = context.getInvite();
     if (mounted && invite.isNotEmpty){
      try {
        final decoded = String.fromCharCodes(base64.decode(invite));
        final inviteDate = DateTime.parse(decoded);
        final now = DateTime.now();
        final diff = now.difference(inviteDate);
        if (diff.inHours < 24) {
           setState(() {
            _invited = true;
           });
        }else{
          context.showMessageBox("This invite is no longer valid");
        }
      } catch (e) {
       // pass
      }
     }

     setState(() {
        _initialized = true;
     });
  }

  @override
  void initState() {
    super.initState();
    _checkInvite();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
          if (_initialized && !_invited) ...[
            Center(child: const Text('TB Chess currently requires an invite from an existing player to join.')),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children:[ 
              ElevatedButton(
                onPressed: () async{
                  await launchUrl(Uri.parse("https://tbchess.org/invite.htm"));
                },
                child: Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 4, horizontal:12),
                  child: Text('Request an Invite'),
                ),
              ),
              ],
            ),
          ],

          if (_initialized && _invited) ...[
            const Text('Glory awaits. Create your account to join a battle:', textAlign: TextAlign.center,),
            const SizedBox(height: 18),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onFieldSubmitted:(value) {
                if (!_isLoading) _register();
              }
            ),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children:[ 
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 4, horizontal:12),
                  child: Text(_isLoading ? 'Creating account...' : 'Create Account'),
                ),
              ),
              ],
            ),
          ],
          
          if (_initialized) ...[
            const SizedBox(height: 18),
            TextButton(
              onPressed: () {
                context.go('/login');
              },
              child: const Text('Already have an account?'),
            ),
          ],
        ],
      ),
    );
  }
}
