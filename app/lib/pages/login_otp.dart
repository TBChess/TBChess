import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class LoginOTPPage extends StatefulWidget {
  final String otpId;
  const LoginOTPPage(this.otpId, {super.key});

  @override
  State<LoginOTPPage> createState() => _LoginOTPPageState();
}

class _LoginOTPPageState extends State<LoginOTPPage> {
  bool _isLoading = false;

  Future<void> _signIn(String otp) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final authData = await pb.collection('users').authWithOTP(widget.otpId, otp);

      if (mounted && pb.authStore.isValid) {
        prefs.setString("lastEmailLogin", authData.record.getStringValue("email"));

        if (context.getNextPage().isNotEmpty) {
          context.go(context.getNextPage());
        }else{ 
          context.go("/account");
        }
      }
    } on ClientException catch (error){
      if (mounted){
        context.showNetworkError(error, title: "Invalid one time password");
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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In'), centerTitle: true,),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 24),
          const Text(
            'We sent a one-time password to your email:',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OtpTextField(
            numberOfFields: 6,
            borderColor: Colors.blue,
            focusedBorderColor: Colors.blue,
            //set to true to show as box or false to show as dash
            showFieldAsBox: true, 
            //runs when a code is typed in
            onCodeChanged: (String code) {
                //handle validation or checks here           
            },
            //runs when every textfield is filled
            onSubmit: (String otp) async{
                await _signIn(otp);
            }, // end onSubmit
        ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () {
              context.go('/login');
            },
            child: const Text('Sign in with password instead'),
          ),
        ],
      ),
    );
  }
}