import 'dart:async';
import 'dart:math';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tbchessapp/main.dart';

class ClockPage extends StatefulWidget {
  final String time;
  const ClockPage({this.time = "10+0", super.key});

  @override
  State<ClockPage> createState() => _ClockPageState();
}

enum ClockState { started, paused, init, finish }

const msstep = 25;

class _ClockPageState extends State<ClockPage> {
  void playSound() async {
    // TODO
  }

  Duration timePlayer1 = Duration(seconds: 0);
  Duration timePlayer2 = Duration(seconds: 0);
  double delayPlayer1 = 0;
  double delayPlayer2 = 0;
  int playerToMove = 0;
  bool blink1 = false;
  bool blink2 = false;
  int blinkStep = 0;

  int delay = 0;
  int increment = 0;
  Duration time = Duration(minutes: 3);

  late Timer _timer;

  ClockState clockState = ClockState.init;

  void initClock() {
    if (widget.time.contains("+")){
      try{
        final parts = widget.time.split("+").map((p) => int.parse(p)).toList();
        if (parts.length == 2){
          time = Duration(minutes: parts[0]);
          increment = parts[1];
        }
      }catch(_){
        // pass
      }
    }
    blink1 = blink2 = false;
    timePlayer1 = Duration(microseconds: time.inMicroseconds) + Duration(milliseconds: 999);
    timePlayer2 = Duration(microseconds: time.inMicroseconds) + Duration(milliseconds: 999);
    delayPlayer1 = delayPlayer2 = 0;
    clockState = ClockState.init;    
  }

  @override
  void initState() {
    super.initState();
    initClock();
  }

  @override
  void dispose(){
    super.dispose();
  }

  void onRestartPressed(BuildContext context) {
    if (clockState == ClockState.paused || clockState == ClockState.finish) {
      setState(() {
        initClock();
      });
    }
  }

  void onPausePressed() {
    if (clockState == ClockState.started) {
      setState(() {
        clockState = ClockState.paused;
        _timer.cancel();
      });
    } else if (clockState == ClockState.paused) {
      // pause it:
      setState(() {
        clockState = ClockState.started;
        _timer = Timer.periodic(Duration(milliseconds: msstep), tickHandler);
      });
    }
  }

  void onHomePressed() {
    context.goBackOrTo("/");
  }

  void tickHandler(Timer timer){
    if (clockState == ClockState.started) {
      setState(() {
        if (playerToMove == 1) {
          if (delayPlayer1 > 0) {
            delayPlayer1 -= msstep / 1000;
          } else {
            timePlayer1 -= Duration(milliseconds: (msstep - delayPlayer1).toInt());

            if (timePlayer1.inMilliseconds <= 0) {
              clockState = ClockState.finish;
              playSound();
            }
          }
        } else if (playerToMove == 2) {
          if (delayPlayer2 > 0) {
            delayPlayer2 -= msstep / 1000;
          } else {
            timePlayer2 -= Duration(milliseconds: (msstep - delayPlayer2).toInt());
            if (timePlayer2.inMilliseconds <= 0) {
              clockState = ClockState.finish;
              playSound();
            }
          }
        }
      });
    } else if (clockState == ClockState.finish){
      setState((){
        int curBlinkStep = (DateTime.now().millisecond ~/ 500) % 2;
        if (curBlinkStep != blinkStep){
          blinkStep = curBlinkStep;
          if (timePlayer1.inMilliseconds <= 0) {
            blink1 = !blink1;
          }
          if (timePlayer2.inMilliseconds <= 0) {
            blink2 = !blink2;
          }
        }
      });
    } else {
      timer.cancel();
    }
  }

  void startClock(int player) {
    if (clockState != ClockState.init) return;
    setState(() {
      blink1 = blink2 = false;
      clockState = ClockState.started;
      if (player == 1){
        playerToMove = 2;
        delayPlayer2 = delay.toDouble();
        delayPlayer1 = 0;
      }else{
        playerToMove = 1;
        delayPlayer1 = delay.toDouble();
        delayPlayer2 = 0;
      }
      _timer = Timer.periodic(Duration(milliseconds: msstep), tickHandler);
    });
  }

  void onPlayerTap(int player) {
    // Keep screen turned on and go fullscreen
    if (kIsWeb){
      try{
        web.window.navigator.wakeLock.request('screen');
      }catch(_){
        // pass
      }
    }

    if (clockState == ClockState.init) {
      startClock(player);
    }
    if (clockState == ClockState.started) {
      if (player == playerToMove) {
        setState(() {
          if (playerToMove == 1) {
            playerToMove = 2;
            delayPlayer2 = delay.toDouble();
            timePlayer1 += Duration(seconds: increment);
            delayPlayer1 = 0;
          } else if (playerToMove == 2) {
            playerToMove = 1;
            delayPlayer1 = delay.toDouble();
            timePlayer2 += Duration(seconds: increment);
            delayPlayer2 = 0;
          }
        });
      }
    }
  }

  String duration2str(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    int hours = d.inHours.remainder(60);
    int minutes = d.inMinutes.remainder(60);
    int seconds = d.inSeconds.remainder(60);
    if (hours != 0) {
      return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
    } else {
      return "$minutes:${twoDigits(seconds)}";
    }
  }

  @override
  build(BuildContext context) {
    String displayTime1 = duration2str(timePlayer1);
    String displayTime2 = duration2str(timePlayer2);
    if (blink1 && clockState == ClockState.finish) displayTime1 = "";
    if (blink2 && clockState == ClockState.finish) displayTime2 = "";

    List<Widget> buttons = [];

    if (clockState == ClockState.finish || clockState == ClockState.paused) {
      buttons.add(
        FloatingActionButton(
          onPressed: () => onRestartPressed(context),
          heroTag: null,
          backgroundColor: Colors.blue,
          child: Icon(Icons.replay),
        ),
      );
    }
    if (clockState == ClockState.started){
      buttons.add(FloatingActionButton(
        onPressed: onPausePressed,
        heroTag: null,
        backgroundColor: Colors.blue,
        child: Icon(Icons.pause),
      ));
    }
    if (clockState == ClockState.paused){
      buttons.add(FloatingActionButton(
        onPressed: onPausePressed,
        heroTag: null,
        backgroundColor: Colors.blue,
        child: Icon(Icons.play_arrow),
      ));
    }
    if (clockState == ClockState.init || clockState == ClockState.paused){
      buttons.add(FloatingActionButton(
        onPressed: onHomePressed,
        heroTag: null,
        backgroundColor: Colors.blue,
        child: Icon(Icons.home),
      )); 
    }

    return Scaffold(
        body: Stack(children: [
              Column(
                children: [
                  Expanded(
                      flex: 3,
                      child: Transform.rotate(
                        angle: pi,
                        child: Stack(
                          children: [
                            Material(
                                color: (clockState == ClockState.init || playerToMove == 2) ? Colors.grey[900] : Colors.grey[700],
                                child: InkWell(
                                    highlightColor: Colors.grey[800],
                                    splashColor: Colors.grey[800],
                                    onTap: () {
                                      onPlayerTap(2);
                                    },
                                    child: Stack(children: [
                                      Center(
                                        child: Text(
                                          displayTime2,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 90,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ]))),
                          ],
                        ),
                      )),
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Material(
                            color: (clockState == ClockState.init || playerToMove == 1) ? Colors.grey[900] : Colors.grey[700],
                            child: InkWell(
                                highlightColor: Colors.grey[800],
                                splashColor: Colors.grey[800],
                                onTap: () {
                                  onPlayerTap(1);
                                },
                                child: Stack(children: [
                                  Center(
                                    child: Text(
                                      displayTime1,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 90,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ]))),
                      ],
                    ),
                  ),
                ],
              ),
              Row(children: [
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: buttons,
                    ),
                  ),
                )
              ])
            ])
          );
  }
}
