import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';
import 'package:tbchessapp/widgets/event_leaderboard.dart';

class LeaderBoardPage extends StatefulWidget {
  final String venueId;
  const LeaderBoardPage(this.venueId, {super.key});

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage> {
  bool _isLoading = false;
  RecordModel? _venue;
  List<RecordModel>? _games;

  Future<void> _getVenue() async {
    try {
      setState(() {
        _isLoading = true;
      });

      _venue = await pb.collection("venues").getOne(widget.venueId);
      _games = await pb.collection("games_list").getFullList(
          filter: 'event.venue="${widget.venueId}" && event.finished = 1 && finished = 1',
        );
      
    } on ClientException catch (error){
      if (mounted){
        await context.showNetworkError(error, title: "Cannot fetch leaderboard");
        if (mounted){
          context.go("/");
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
    _getVenue();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venueName = _venue?.getStringValue("name") ?? "";
    String venueLogoUrl = "";
    if (_venue != null) {
      venueLogoUrl = pb.files.getUrl(_venue!, _venue!.getStringValue("logo")).toString();
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isLoading ? "Loading..." : venueName), 
                     centerTitle: true,
                     leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          context.goBackOrTo('/');
                        },
                    ),),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (venueLogoUrl.isNotEmpty)  Image.network(venueLogoUrl, width: 72, height: 72),
          if (_games != null) ...[const SizedBox(height: 16), EventLeaderboard(_games!, title: "Season Standings", wdl: false)],
        ],
      ),
    );
  }
}