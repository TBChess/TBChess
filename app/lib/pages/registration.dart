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
  late final TextEditingController _usernameController = TextEditingController();
  late final TextEditingController _passwordController = TextEditingController();

  Future<void> _register() async {
    final email = _usernameController.text.trim();

    if (email.isEmpty || _passwordController.text.trim().isEmpty) {
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
        "email": email,
        "password": _passwordController.text.trim(),
        "passwordConfirm":  _passwordController.text.trim(),
        "emailVisibility": false
      };

      await pb.collection('users').create(body: body);

      // Automatically sign in the user after successful registration
      await pb.collection('users').authWithPassword(
        email,
        _passwordController.text.trim(),
      );

      if (mounted) {
        prefs.setString("lastEmailLogin", email);

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

  @override
  void initState() {
    super.initState();

    try{
      _usernameController.text = prefs.getString("lastEmailLogin") ?? "";
    }catch (_){
      // pass
    }
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
      appBar: AppBar(title: const Text('Register'), centerTitle: true,
          leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/login');
          },
        ),
      ),
      
      body: ListView(
        padding: const EdgeInsets.symmetric( horizontal: 16),
        children: [
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
            const SizedBox(height: 18),
            TextButton(
              onPressed: () {
                context.go('/login_email');
              },
              child: const Text('Already have an account?'),
            ),
          ],          
      ),
    );
  }
}
