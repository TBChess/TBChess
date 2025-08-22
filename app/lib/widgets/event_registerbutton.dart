import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:go_router/go_router.dart';
import 'package:tbchessapp/main.dart';

class EventRegisterButton extends StatefulWidget {
  final RecordModel event;
  final bool signedUp;
  final bool registered;
  final bool byob;
  final void Function(RecordModel)? onRegister;
  final void Function(String)? onUnregister;
  final bool hideIfDisabled;
  final bool cancelLabel;

  const EventRegisterButton(this.event, this.signedUp, this.registered, this.byob, {this.onRegister, this.onUnregister, this.cancelLabel = false, this.hideIfDisabled = false, super.key});

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
        context.goAuthPage();
        return;
      }

      if (register){
        setState(() {
          _updatingReg = true;      
        });
        final json = await pb.send("/api/tbchess/event/$eid/register", method: "POST");
        final record = RecordModel.fromJson(json);
        bool started = widget.event.getBoolValue('started');

        record.data["username"] = pb.authStore.record?.getStringValue("name");
        if (widget.onRegister != null) widget.onRegister!(record);
        setState(() {
          _signedUp = true;
        });

        if (mounted){
          bool waitlist = record.getBoolValue("waitlist");
          List<String> parts = [];
          parts.add(!waitlist ? "You're signed up!" : "You're on the waitlist.");
          if (started){
            parts.add("Ask the event coordinator to confirm your registration.");
          }else{
            parts.add(!waitlist ? "If something changes and you cannot make it to the event, please update your registration so that others may play." : "You can still come to the event and play if someone doesn't show up. If someone unregisters we will bump you up on the registration list. Check your status the day of the event.");
          }
          if (!started && widget.byob) parts.add("Bring a chess board with you, if you have one, as the venue does not provide them.");

          context.showMessageBox(parts.join("\n\n"));
        }
      }else{
        if (mounted){
          if (await context.showConfirmDialog("Are you sure you want to unregister?")){
            setState(() {
              _updatingReg = true;      
            });
            await pb.send("/api/tbchess/event/$eid/unregister", method: "POST");

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
    bool lateRegAllowed = widget.event.getIntValue("current_round") <= widget.event.getIntValue("rounds") / 2;
    bool started = widget.event.getBoolValue('started');
    bool finished = widget.event.getBoolValue('finished');

    String buttonText = "Register";
    Color buttonColor = Colors.blue;
    if (_signedUp){
      buttonText = "Registered";
      buttonColor = Colors.green;
      if (widget.cancelLabel){
        buttonText = "Unregister";
        buttonColor = Colors.red;
      }
    }else{
      if (started && lateRegAllowed){
        buttonText = "Register Late";
      }
    }

    final inProgress = started && (!lateRegAllowed || widget.registered);
    
    if (inProgress){
      buttonText = "In Progress";
      buttonColor = Colors.teal;
    }
    if (finished){
      buttonText = "Finished";
    }

    if (widget.hideIfDisabled && (inProgress || finished)){
      return Container();
    }

    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          minimumSize: const Size(120, 36),
        ),
        onPressed: _updatingReg || inProgress || finished ? null : () => _updateRegistration(!_signedUp),
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

