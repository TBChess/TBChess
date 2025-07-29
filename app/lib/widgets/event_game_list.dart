import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class EventGameList extends StatelessWidget  {
  final List<RecordModel> games;

  const EventGameList(this.games, {super.key});

  @override
  Widget build(BuildContext context) {
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
              ],
        );
      },
    );
  }
}