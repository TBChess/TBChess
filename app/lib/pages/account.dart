import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';
import 'package:tbchessapp/utils/push.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();
  final _eloController = TextEditingController();
  bool _hideElo = true;
  bool _notifications = false;
  bool _starterElo = true;
  double _eloSliderValue = 1200.0;
  double _elo = 1200.0;

  var _loading = true;

  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      await pb.collection('users').authRefresh();
      final user = pb.authStore.record!;

      _usernameController.text = user.getStringValue("name", "");
      _hideElo = user.getBoolValue("hide_elo", false);
      _starterElo = user.getBoolValue("starter_elo", false);
      _notifications = user.getStringValue("webpush_sub", "").isNotEmpty;
      _elo = user.getDoubleValue("elo", 1200);
      _eloSliderValue = _elo.toDouble();
      if (!_starterElo) _eloSliderValue = _eloSliderValue.clamp(600.0, 1800.0);

      _eloController.text = _elo.round().toString();
    } on ClientException catch (error){
      if (mounted){
        if (!pb.authStore.isValid){
          context.go("/login");
        }else{
          context.showNetworkError(error, title: "Cannot get profile");
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Called when user taps `Update` button
  Future<void> _updateProfile({bool showSaved = true}) async {
    setState(() {
      _loading = true;
    });
    final userName = _usernameController.text.trim();
    try {
      if (userName.isEmpty) {
        throw FormatException('Username cannot be empty');
      }

      final body = <String, dynamic>{
        "name": userName,
        "hide_elo": _hideElo,
      };

      if (!_starterElo && _elo.round() != _eloSliderValue.round()){
        if (!await context.showConfirmDialog("You've set an ELO of ${_eloSliderValue.round()}. Is this correct? You can only set this once.")){
          setState(() {
            _eloSliderValue = _elo.toDouble();
          });
          return;
        }

        body["starter_elo"] = true;
        body["elo"] = _eloSliderValue.round();
        _starterElo = true;
        _elo = body["elo"];
      }

      await pb.collection('users').update(pb.authStore.record!.id, body: body);
      if (mounted) {
        if (showSaved) context.showSnackBar('Profile saved!');
      }
     } on ClientException catch (error){
      if (mounted){
        context.showNetworkError(error, title: "Cannot update profile");
      }
     } on FormatException catch (error){
      if (mounted){
        context.showMessageBox(error.message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      pb.authStore.clear();
    } catch (error) {
      if (mounted) {
        context.showMessageBox(error.toString());
      }
    } finally {
      if (mounted) {
        context.go("/");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _eloController.dispose();
    super.dispose();
  }

  void enablePush() async{
    try{
      await setupWebPush();
      setState(() {
        _notifications = true;
      });
    }catch(e){
      setState(() {
        _notifications = false;
      });
    }
  }

  void disablePush() async{
    try{
      await cancelWebPush();
      setState(() {
        _notifications = false;
      });
    }catch(e){
      setState(() {
        _notifications = true;
      });
    }
  }

  void togglePush() async{
    if (_notifications){
      disablePush();
    }else{
      enablePush();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text('Profile'), 
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.go('/events');
        },
      ),
      ),
      body: ListView(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                onChanged: (value) {
                  setState(() {
                    // Trigger rebuild to show/hide button
                  });
                },
                onFieldSubmitted:(value) {
                  if (!_loading) _updateProfile();
                },
              ),
            ),
            if (_usernameController.text.trim() != (pb.authStore.record?.getStringValue("name", "") ?? "")) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _loading ? null : _updateProfile,

              child: const Icon(Icons.check),
            ) ,
            ],
          ],
        ),


        if (supportsPushNotifications()) ...[SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: deniedPushNotifications() ? null : togglePush,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Round Notifications',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Text(
                        'Be notified when a new round starts',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              Switch(
                value: _notifications,
                onChanged: deniedPushNotifications() ? null : (bool value) {
                  togglePush();
                },
              ),
            ],
          ),
        ],

        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _loading ? null : () {
                  setState(() {
                    _hideElo = !_hideElo;
                    _updateProfile(showSaved: false);
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hide ELO',
                      style: TextStyle(fontSize: 16),
                    ),
                    const Text(
                      'When enabled, ELO ratings will be hidden',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            Switch(
              value: _hideElo,
              onChanged: _loading ? null : (bool value) {
                setState(() {
                  _hideElo = value;
                });
                _updateProfile(showSaved: false);
              },
            ),
          ],
        ),

        const SizedBox(height: 24),
        
        // ELO Rating Section
        if (!_starterElo) Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Starting ELO Rating',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              'In order to play better matches, you can set your starting ELO to the closest value of your online ELO',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // ELO Text Field
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _eloController,
                    decoration: const InputDecoration(
                      labelText: 'ELO Rating',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value.isEmpty) return;
                      
                      final intValue = int.tryParse(value);
                      if (intValue != null) {
                        setState(() {
                          _eloSliderValue = intValue.toDouble().clamp(600.0, 1800.0);
                        });
                      }else{
                        // Reset to previous valid value or default
                        final previousValue = _eloSliderValue.round().toString();
                        _eloController.text = previousValue;
                        _eloController.selection = TextSelection.fromPosition(
                          TextPosition(offset: previousValue.length),
                        );
                      }
                    },
                    onFieldSubmitted: (value) {
                      if (!_loading) _updateProfile();
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            // ELO Slider
            Column(
              children: [
                Slider(
                  value: _eloSliderValue,
                  min: 600.0,
                  max: 1800.0,
                  divisions: 120, // 10-point increments
                  label: _eloSliderValue.round().toString(),
                  onChanged: _loading ? null : (double value) {
                    setState(() {
                      _eloSliderValue = value;
                      _eloController.text = value.round().toString();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('600', style: TextStyle(color: Colors.grey)),
                    const Text('1800', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ],
        ),

        if (_starterElo && !_hideElo) 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ELO',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                _eloSliderValue.round().toString(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),

        const SizedBox(height: 48),
        TextButton(onPressed: _signOut, child: const Text('Sign Out')),
      ],
      ),
    );
  }
}