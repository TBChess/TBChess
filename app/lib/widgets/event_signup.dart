import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';

enum EventSignupAction { None, BumpToWaitList, BumpToRegistered }

class EventSignup extends StatefulWidget {
  final RecordModel signup;
  final EventSignupAction action;

  const EventSignup(this.signup, {this.action = EventSignupAction.None, super.key});

  @override
  State<EventSignup> createState() => _EventSignupState();
}

class _EventSignupState extends State<EventSignup> {

  bool _actionPending = false;

  @override
  Widget build(BuildContext context) {
    final username = widget.signup.get<String>('username');
    final elo = widget.signup.get<double>('elo').round();
    final hideElo = pb.authStore.isValid && pb.authStore.record!.getBoolValue("hide_elo");

    return InkWell(
      onTap: () {
        print("Tapped $username");
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
          const Icon(Icons.person, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            hideElo ? username : "$username ($elo)",
            style: const TextStyle(
            color: Colors.white,
            ),
          ),

          if (_actionPending) ...[
            Expanded(child: SizedBox()),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          ],

          if (!_actionPending && widget.action == EventSignupAction.BumpToWaitList) ...[
            Expanded(child: SizedBox()),
            TextButton(
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              fixedSize: Size(28, 28)
            ),
            onPressed: () async {
              if (await context.showConfirmDialog("Are you sure you want to move $username to the wait list?")){
                try{
                  setState((){ _actionPending = true; });
                  await pb.collection('event_signups').update(widget.signup.id, body: {
                    "waitlist": true
                  });
                } on ClientException catch (error){
                  if (mounted){
                    context.showNetworkError(error);
                  }
                } finally {
                  if (mounted) {
                    setState((){ _actionPending = false; });
                  }
                }
              }
            },
            child: Icon(
              Icons.remove_circle,
              size: 28,
              color: Colors.red,
            ),
          ),
          ],

          if (!_actionPending && widget.action == EventSignupAction.BumpToRegistered) ...[
            Expanded(child: SizedBox()),
            TextButton(
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              fixedSize: Size(28, 28)
            ),
            onPressed: () async {
              if (await context.showConfirmDialog("Are you sure you want to move $username into the tournament?")){
                try{
                  setState((){ _actionPending = true; });
                  await pb.collection('event_signups').update(widget.signup.id, body: {
                    "waitlist": false
                  });
                } on ClientException catch (error){
                  if (mounted){
                    context.showNetworkError(error);
                  }
                } finally {
                  if (mounted) {
                    setState((){ _actionPending = false; });
                  }
                }
              }
            },
            child: Icon(
              Icons.add_circle,
              size: 28,
              color: Colors.green,
            ),
          ),
          ]

          ],
        ),
      ),
    );
  }
}