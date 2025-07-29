import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';
import 'package:go_router/go_router.dart';
import 'package:tbchessapp/utils/games.dart';
import 'package:tbchessapp/widgets/report_score_dialog.dart';

class EventVS extends StatefulWidget  {
  final RecordModel game;

  const EventVS(this.game, {super.key});

  @override
  State<EventVS> createState() => _EventVSState();
}

class _EventVSState extends State<EventVS>{
  bool _reportingScore = false;

 Future<void> _reportScore(MatchResult matchResult) async{
  try{
      final gid = widget.game.id;
      
      if (!pb.authStore.isValid){
        context.go("/");
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

  @override
  Widget build(BuildContext context) {
      RecordModel game = widget.game;

      final result = game.getDoubleValue("result");
      bool finished = game.getBoolValue("finished");
      bool bye = game.getBoolValue("bye");
      bool whiteWon = finished && result == 1.0;
      bool blackWon = finished && result == 0.0;
      bool draw = finished && result == 0.5;
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

      Widget whiteIco = icoPlaceholder;
      Widget blackIco = icoPlaceholder;
      Widget matchIco = icoPlaceholder;
      Widget whitePts = Container();
      Widget blackPts = Container();

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
        }else if (blackWon){
          blackIco = winIcon;
          blackPts = winPts;
          whitePts = lostPts;
        }else if (draw){
          whiteIco = drawIcon;
          blackIco = drawIcon;
          whitePts = drawPts;
          blackPts = drawPts;
        }
      }

      Widget bottomText = Container();
      List<Widget> reportScore = [Container()];

      String userColor = "";
      if (userId != null){

        userColor = getUserColor(game, userId);

        TextStyle s = TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                );
        if (!finished){
          if (bye){
            bottomText = Text("You're sitting this round out", style: s);
          }else{
            bottomText = RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: "You are playing with the "),
                    TextSpan(text: userColor, style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: " pieces")
                  ],
                  style: s,
                ),              
              );
            
            reportScore = [ const SizedBox(height: 16), ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(160, 52),
              ),
              onPressed: () => {
                ReportScoreDialog.show(
                  context,
                  onResultSelected: _reportScore,
                  title: "Round ${game.getIntValue("round")}"
                )
              },
              child: Text("Report Score")
            )];
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
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.person, size: 32, color: Colors.blue),
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
                        const SizedBox(height: 4),
                        whitePts,
                        const SizedBox(height: 8),
                        whiteIco,
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
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.person, size: 32, color: Colors.red),
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

                        const SizedBox(height: 4),
                        blackPts,
                        const SizedBox(height: 8),
                        blackIco,
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
            ...reportScore,
        ],)
      ],
    );
  }
}