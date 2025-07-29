import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:go_router/go_router.dart';
import 'package:tbchessapp/main.dart';

class EventRegisterButton extends StatefulWidget {
  final RecordModel event;
  final bool byob;
  final bool signedUp;
  final void Function(RecordModel)? onRegister;
  final void Function(String)? onUnregister;
  final bool hideWhenStarted;
  const EventRegisterButton(this.event, this.signedUp, this.byob, {this.onRegister, this.onUnregister, this.hideWhenStarted = false, super.key});

  @override
  State<EventRegisterButton> createState() => _EventRegisterButtonState();
}

class _EventRegisterButtonState extends State<EventRegisterButton> {
  bool _updatingReg = false;
  bool _signedUp = false;

  @override
  void initState() {
    _signedUp = widget.signedUp;
    super.initState();
  }

  Future<void> _updateRegistration(bool register) async{
    try{
      final uid = pb.authStore.record?.id;
      final eid = widget.event.id;
      
      if (!pb.authStore.isValid){
        context.setNextPage("/event/$eid");
        context.go("/");
        return;
      }

      if (register){
        setState(() {
          _updatingReg = true;      
        });
        final record = await pb.collection('event_signups').create(body: {
          "user": uid,
          "event": eid
        });

        record.data["username"] = pb.authStore.record?.getStringValue("name");
        if (widget.onRegister != null) widget.onRegister!(record);
        setState(() {
          _signedUp = true;
        });

        if (mounted){
          context.showMessageBox("You're signed up!\n\nIf something changes and you cannot make it to the event, please update your registration so that others may play.${widget.byob ? "\n\nBring a chess board with you, if you have one, as the venue does not provide them." : ""}");
        }
      }else{
        if (mounted){
          if (await context.showConfirmDialog("Are you sure you want to unregister?")){
            setState(() {
              _updatingReg = true;      
            });
            final es = await pb.collection('event_signups').getFirstListItem(
              'user="$uid" && event="$eid"',
            );
            await pb.collection('event_signups').delete(es.id);

            setState(() {
              _signedUp = false;
            });
            if (widget.onUnregister != null) widget.onUnregister!(uid!);

          }
        }
      }
    } on ClientException catch (error){
      if (mounted){
        context.showNetworkError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingReg = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = "Register";
    Color buttonColor = Colors.blue;
    if (_signedUp){
      buttonText = "Registered";
      buttonColor = Colors.green;
    }
    bool started = widget.event.getBoolValue('started');
    bool finished = widget.event.getBoolValue('finished');
    if (started){
      buttonText = "In Progress";
      buttonColor = Colors.teal;
    }
    if (finished){
      buttonText = "Finished";
    }

    if (started && widget.hideWhenStarted) return Container();

    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          minimumSize: const Size(120, 36),
        ),
        onPressed: _updatingReg || started ? null : () => _updateRegistration(!_signedUp),
        child: _updatingReg 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 3)
            )
          : Text(buttonText)
      );
  }
}

