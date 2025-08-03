import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/widgets/adjust_score_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:tbchessapp/main.dart';

class EventGameList extends StatefulWidget  {
  final List<RecordModel> games;
  final bool isOwner;

  const EventGameList(this.games, {this.isOwner = false, super.key});

  @override
  State<EventGameList> createState() => _EventGameListState();
}

class _EventGameListState extends State<EventGameList>  {
  bool _adjustingScore = false;

  Future<void> _adjustScore(String gameId, MatchAdjustmentResult matchResult) async{
  try{
      if (!pb.authStore.isValid){
        context.go("/");
        return;
      }
      
      double result = 0.0;
      if (matchResult == MatchAdjustmentResult.whiteWon){
        result = 1.0;
      }else if (matchResult == MatchAdjustmentResult.blackWon){
        result = 0.0;
      }else if (matchResult == MatchAdjustmentResult.draw){
        result = 0.5;
      }

      await pb.send("/api/tbchess/game/$gameId/finish", method: "POST", body: {
        "result": result,
      });
      
      setState(() {
        _adjustingScore = true;      
      });

    } on ClientException catch (error){
      if (mounted){
        context.showNetworkError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _adjustingScore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = widget.games;
    if (games.isEmpty) {
      return Container();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final whiteName = game.getStringValue('white_name');
        String blackName = game.getStringValue('black_name');
        final result = game.getDoubleValue("result");
        final finished = game.getBoolValue("finished");
        final bye = game.getBoolValue("bye");

        final winIcon =  Icon(
          Icons.check_circle,
          color: Colors.lightGreen,
          size: 24,
        );
        final drawIcon =  Icon(
          Icons.drag_handle,
          color: Colors.white,
          size: 24,
        );
      
        final icoPlaceholder =  SizedBox(height: 24);
        Widget whiteIco = icoPlaceholder;
        Widget blackIco = icoPlaceholder;
        bool whiteWon = finished && result == 1.0;
        bool blackWon = finished && result == 0.0;
        bool draw = finished && result == 0.5;
        TextStyle blackStyle = const TextStyle();

        if (!finished){
          whiteIco = blackIco = Icon(
            Icons.access_time,
            color: Colors.green,
            size: 24,
          );
        }else{
          if (whiteWon){
            whiteIco = winIcon;
          }else if (blackWon){
            blackIco = winIcon;
          }else if (draw){
            whiteIco = drawIcon;
            blackIco = drawIcon;
          }
        }

        if (bye){
          blackStyle = const TextStyle(
              fontStyle: FontStyle.italic,
            );
          blackName = "unpaired";
          blackIco = icoPlaceholder;
        }

        return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        whiteName,
                      ),
                    ),
                    whiteIco,
                  ],
                ),
                const SizedBox(height: 8),
                
                // Black player row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        blackName,
                        style: blackStyle,
                      ),
                    ),
                    blackIco,
                  ],
                ),

                if (widget.isOwner && !bye) ...[const SizedBox(height: 8), Center(child: TextButton(
                  onPressed: (){
                    AdjustScoreDialog.show(
                      context,
                      onResultSelected: (MatchAdjustmentResult result){
                        _adjustScore(game.id, result);
                      },
                      title: "$whiteName vs. $blackName"
                    );
                  },
                  child: _adjustingScore 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 3)
                      )
                    : Text(finished ? "Adjust Score" : "Report Score")
                ))],
              ],
        );
      },
    );
  }
}