import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class EventLeaderboard extends StatelessWidget  {
  final List<RecordModel> games;
  final String title;

  const EventLeaderboard(this.games, {this.title = "Standings", super.key});

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return Container();
    }

    HashMap<String, Map> players = HashMap<String, Map>();
    Map player = {
      'name': '',
      'wins': 0,
      'losses': 0,
      'draws': 0,
      'pts': 0
    };

    games.forEach((g){
      final whiteName = g.getStringValue("white_name");
      final blackName = g.getStringValue("black_name");

      if (!players.containsKey(whiteName)){
        players[whiteName] = Map.from(player);
        players[whiteName]!['name'] = whiteName;
      }
      if (blackName.isNotEmpty && !players.containsKey(blackName)){
        players[blackName] = Map.from(player);
        players[blackName]!['name'] = blackName;
      }

      Map whitePlayer = players[whiteName]!;
      Map? blackPlayer;
      if (blackName.isNotEmpty){
         blackPlayer = players[blackName];
      }

      final result = g.getDoubleValue("result");
      final finished = g.getBoolValue("finished");
      final bye = g.getBoolValue("bye");

      if (finished){
        // White won
        if (result == 1.0 || bye){
          whitePlayer['wins'] += 1;
          whitePlayer['pts'] += 100;
          if (blackPlayer != null && !bye){
            blackPlayer['losses'] += 1;
            blackPlayer['pts'] += 20;
          }
        // Black won
        }else if (result == 0.0){
          whitePlayer['losses'] += 1;
          whitePlayer['pts'] += 20;
          if (blackPlayer != null){
            blackPlayer['wins'] += 1;
            blackPlayer['pts'] += 100;
          }
        // Draw
        }else if (result == 0.5){
          whitePlayer['draws'] += 1;
          whitePlayer['pts'] += 60;
          if (blackPlayer != null){
            blackPlayer['draws'] += 1;
            blackPlayer['pts'] += 60;
          }
        }
      }
    });

    List<Map> sortedPlayers = players.values.toList();
    sortedPlayers.sort((a, b) => b['pts'].compareTo(a['pts']));

    bool wideScreen = MediaQuery.of(context).size.width >= 420;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedPlayers.length,
              itemBuilder: (context, index) {
                final player = sortedPlayers[index];
                bool printRank = index == 0 || sortedPlayers[index - 1]['pts'] != player['pts'];

                return Column(
                      children: [
                        if (index == 0)
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 3, child: Text('Player', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('W/D/L', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text(wideScreen ? 'Points' : 'Pts', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: printRank ? Text('${index + 1}') : Text(''),
                              ),
                              Expanded(flex: 3, child: Text(player['name'], overflow: TextOverflow.ellipsis, maxLines: 1,)),
                              Expanded(flex: 2, child: Text('${player['wins']}/${player['draws']}/${player['losses']}')),
                              Expanded(flex: 1, child: Text('${player['pts']}')),
                            ],
                          ),
                        ),
                      ],
                );
              },
            )

            ],
          ),
          ),
        );
  }
}