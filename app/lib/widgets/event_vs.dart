import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';
import 'package:tbchessapp/utils/games.dart';
import 'package:tbchessapp/widgets/report_score_dialog.dart';
import 'package:tbchessapp/utils/date.dart';

class EventVS extends StatefulWidget  {
  final RecordModel game;
  final String time;
  final int submitScoreCooldown;

  const EventVS(this.game, this.time, {this.submitScoreCooldown = 0, super.key});

  @override
  State<EventVS> createState() => _EventVSState();
}

class _EventVSState extends State<EventVS>{
  bool _reportingScore = false;
  Timer? _cooldownTimer;
  int _reportCooldown = 0;

 Future<void> _reportScore(MatchResult matchResult) async{
  try{
      final gid = widget.game.id;
      
      if (!pb.authStore.isValid){
        context.goAuthPage();
        return;
      }
      
      final userId = pb.authStore.record!.id;
      String userColor = getUserColor(widget.game, userId);

      double result = 0.0;
      if (matchResult == MatchResult.Won){
        if (userColor == "white"){
          result = 1.0;
        }
        else if (userColor == "black") {
          result = 0.0; 
        }
      }else if (matchResult == MatchResult.Lost){
        if (userColor == "white"){
          result = 0.0;
        }else if (userColor == "black"){
          result = 1.0;
        }
      }else if (matchResult == MatchResult.Draw){
        result = 0.5;
      }

      await pb.send("/api/tbchess/game/$gid/finish", method: "POST", body: {
        "result": result,
      });
      
      setState(() {
        _reportingScore = true;      
      });

    } on ClientException catch (error){
      if (mounted){
        context.showNetworkError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _reportingScore = false;
        });
      }
    }
  }

  void cooldownTick(Timer t){
    setState((){
      if (_reportCooldown > 0){
        _reportCooldown -= 1;
      }else{
        t.cancel();
      }
    });
  }

  @override
  void dispose(){
    if (_cooldownTimer != null){
      _cooldownTimer!.cancel();
      _cooldownTimer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      RecordModel game = widget.game;

      final result = game.getDoubleValue("result");
      bool finished = game.getBoolValue("finished");
      bool bye = game.getBoolValue("bye");
      bool whiteWon = finished && result == 1.0;
      bool blackWon = finished && result == 0.0;
      bool draw = finished && result == 0.5;
      final created = parseDateString(game.getStringValue("created"));
      if (created != null){
        _reportCooldown = max(0, widget.submitScoreCooldown - max(0, DateTime.now().difference(created).inSeconds));
        if (_reportCooldown > 0 && _cooldownTimer == null){
          _cooldownTimer = Timer.periodic(Duration(milliseconds: 1000), cooldownTick);
        }
      }
      final userId = pb.authStore.record?.id;

      final winIcon =  Icon(
        Icons.check_circle,
        color: Colors.lightGreen,
        size: 24,
      );
      final drawIcon =  Icon(
        // Icons.remove_circle,
        Icons.drag_handle,
        color: Colors.white,
        size: 24,
      );
      
      final icoPlaceholder =  SizedBox(height: 24);

      Widget? whiteIco;
      Widget? blackIco;
      Widget matchIco = icoPlaceholder;
      Widget? whitePts;
      Widget? blackPts;

      Widget winPts = Text("+100");
      Widget lostPts = Text("+20");
      Widget drawPts = Text("+60");
      

      if (!finished){
        matchIco = Icon(
          Icons.access_time,
          color: Colors.green,
          size: 24,
        );
      }else{
        if (whiteWon){
          whiteIco = winIcon;
          whitePts = winPts;
          blackPts = lostPts;
          blackIco = icoPlaceholder;
        }else if (blackWon){
          blackIco = winIcon;
          blackPts = winPts;
          whitePts = lostPts;
          whiteIco = icoPlaceholder;
        }else if (draw){
          whiteIco = drawIcon;
          blackIco = drawIcon;
          whitePts = drawPts;
          blackPts = drawPts;
        }
      }

      Widget bottomText = Container();
      List<Widget> actionButtons = [Container()];

      String userColor = "";
      if (userId != null){

        userColor = getUserColor(game, userId);

        TextStyle s = TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                );
        if (!finished){
          if (bye){
            bottomText = Text("You sit this round out", style: s);
          }else{
            bottomText = RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: "You play with the "),
                    TextSpan(text: userColor, style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: " pieces")
                  ],
                  style: s,
                ),              
              );
            
            actionButtons = [ const SizedBox(height: 16), 
              Column(children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(160, 52),
                  ),
                  onPressed: (_reportingScore || _reportCooldown > 0) ? null : () => {
                    ReportScoreDialog.show(
                      context,
                      onResultSelected: _reportScore,
                      title: "Round ${game.getIntValue("round")}"
                    )
                  },
                  icon: Icon(Icons.assignment_turned_in),
                  label: Text(_reportCooldown > 0 ? "Report Score ($_reportCooldown)" : "Report Score")
                ),
                const SizedBox(height: 16), 
                ElevatedButton.icon(
                  onPressed: () {
                    context.goPush('/clock/${widget.time}');
                  },
                  icon: const Icon(Icons.punch_clock, size: 16),
                  label: const Text('Open Clock', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                    overlayColor: Colors.grey.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                )
                ]
              ,)];
          }
        }
      }
      
      return Column(children: [
          Row(
          children: [
            // White
            Expanded(
              child: Column(
                children: [
                  InkWell(onTap: () => { print("TODO: profile") }, 
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    width: 200,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.15),
                              blurRadius: 4,
                              spreadRadius: 1,
                              offset: Offset(0, 0),
                            ),
                          ],),
                          child: Icon(Icons.square_rounded, size: 32, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game.getStringValue("white_name"), // Replace with actual player name
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (whitePts != null) ...[const SizedBox(height: 4),
                                              whitePts!],
                        if (whiteIco != null) ...[const SizedBox(height: 8),
                                              whiteIco!],
                      ],
                    ),
                   ),
                  ),
                ],
              ),
              ),
            // VS Divider
            if (!bye) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.yellow, Colors.red],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      "VS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Game status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: matchIco,
                  ),
                ],
              ),
            ),
            // Black
             if (!bye) Expanded(
              child: Column(
                children: [
                   InkWell(onTap:() => { print("TODO: profile page")}, child: 
                   Container(
                    padding: const EdgeInsets.all(12),
                    width: 200,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                              offset: Offset(0, 0),
                            ),
                          ],),
                          child: Icon(Icons.square_rounded, size: 32, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game.getStringValue("black_name"),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (blackPts != null) ...[const SizedBox(height: 4),
                                              blackPts],
                        if (blackIco != null) ...[const SizedBox(height: 8),
                                              blackIco],
                      ],
                    ),
                   ),
                  ),
                ],
              ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            bottomText,
            ...actionButtons,
        ],)
      ],
    );
  }
}