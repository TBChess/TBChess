import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';

class LoginEmailPage extends StatefulWidget {
  const LoginEmailPage({super.key});

  @override
  State<LoginEmailPage> createState() => _LoginEmailPageState();
}

class _LoginEmailPageState extends State<LoginEmailPage> {
  bool _isLoading = false;
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _passwordController = TextEditingController();
  late final FocusNode _passwordFocus = FocusNode();

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    try {
      setState(() {
        _isLoading = true;
      });
      await pb.collection('users').authWithPassword(
        email,
        _passwordController.text.trim(),
      );
      if (mounted) {
        prefs.setString("lastEmailLogin", email);
        _emailController.clear();
        _passwordController.clear();

        if (context.getNextPage().isNotEmpty) {
          context.go(context.getNextPage());
        }else{ 
          context.go("/events");
        }
      }
    } on ClientException catch (error){
      if (mounted){
        if (email.isNotEmpty){
          if (await context.showConfirmDialog("Invalid username or password", confirmText: "Forgot Password?", cancelText: "Try Again")){
            try{
              // Send one time pwd
              final req = await pb.collection('users').requestOTP(email);
              if (mounted){
                context.go("/login_otp/${req.otpId}");
              }
            } on ClientException catch (error){
            if (mounted) {
              context.showNetworkError(error, title: "Cannot send one time password."); 
            }
            }
          }else{
            _passwordFocus.requestFocus();
          }
        }else{
          context.showNetworkError(error, title: "Invalid username or password");
        }
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
  void initState(){
    super.initState();
    try{
      _emailController.text = prefs.getString("lastEmailLogin") ?? "";
    }catch (_){
      // pass
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In'), centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.goBackOrTo('/login');
        },
      ),),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            onFieldSubmitted: (value) {
              if (!_isLoading) _signIn();
            }
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            onFieldSubmitted:(value) {
              if (!_isLoading) _signIn();
            }
          ),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.center, children:[ 
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 4, horizontal:12),
                  child: Text(_isLoading ? 'Signing in...' : 'Sign In'),
                ),
              ),
              ],
            ),

          const SizedBox(height: 18),
          TextButton(
            onPressed: () {
              context.go('/registration');
            },
            child: const Text('Need an account?'),
          ),
        ],
      ),
    );
  }
}