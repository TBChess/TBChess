import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await pb.collection('users').authWithPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
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
        context.showNetworkError(error, title: "Invalid username or password");
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In'), centerTitle: true,),
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
                child: Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 6, horizontal:12),
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