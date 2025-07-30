import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';
import 'package:tbchessapp/utils/events.dart';
import 'package:tbchessapp/widgets/event_datetime.dart';
import 'package:tbchessapp/widgets/event_registerbutton.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  var _loading = true;
  List<RecordModel> _events = [];

  Future<void> _refreshEvents() async {
    setState(() {
      _loading = true;
    });

    try {
      // Get the file URL for the logo field
      final events = await pb.collection('events_list').getFullList(
        sort: '-event_date'
      );

      // Automatically redirect to the first in progress event (on first load)
      // if there's a match in progress
      if (pb.authStore.isValid && mounted && !context.getPageLoadRedirected()){
        for (final event in events) {
          final userSignups = event.data['user_signups'] ?? [];
          final inProgress = event.getBoolValue('started') && !event.getBoolValue("finished");
          if (inProgress && userSignups.contains(pb.authStore.record?.id)) {
            context.setPageLoadRedirected();
            context.go('/event/${event.id}');
            break;
          }
        }
      }

      setState(() {
        _events = events;
      });

    } on ClientException catch (error){
      if (mounted){
        context.showNetworkError(error, title: "Cannot get events list");
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshEvents();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Battles'), 
        centerTitle: true,
        actions: [
            Padding(
            padding: const EdgeInsets.only(right: 12),
            child: pb.authStore.isValid ? IconButton(
              icon: const Icon(Icons.account_circle, size: 32),
              onPressed: () {
               context.go('/account');
              },
            ) : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ..._events.map((event) {
              final data = event.data;

              final title = "${getEventTitle(data)} @ ${data['venue_name']}";
              // final minPlayers = data['min_players'];
              final maxPlayers = data['max_players'];
              final eventDateStr = data['event_date'];
              final venueLogo = data['venue_logo'] ?? '';
              final playersCount = data['players_count'];
              final userSignups = data['user_signups'] ?? [];
              final venueByob = data['venue_byob'] ?? false;
              
              bool signedUp = pb.authStore.isValid && userSignups.contains(pb.authStore.record?.id);

              String venueLogoUrl = '';
              if (!venueLogo.isEmpty){
                venueLogoUrl = pb.files.getUrl(event, venueLogo).toString();
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  onTap: () {
                    context.go('/event/${event.id}');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        // Left side - Event information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 56,
                                    child: venueLogoUrl.isNotEmpty
                                        ? Image.network(venueLogoUrl, width: 48)
                                        : Icon(Icons.event, size: 48, color: Colors.blueAccent),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      EventDateTime(eventDateStr, spacing: 0),
                                      Row(
                                        children: [
                                          const Icon(Icons.people, size: 16),
                                          const SizedBox(width: 4),
                                          Text("$maxPlayers"),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ]
                          ),
                        ),
                        // Right side - Registration info and button
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text(
                                "$playersCount", 
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              )
                            ),
                            Container(
                              padding: EdgeInsets.only(bottom: 6),
                              child: EventRegisterButton(
                                event, 
                                signedUp, 
                                venueByob, 
                                onRegister: (r){
                                  event.data["players_count"] += 1;
                                  event.data['user_signups'].add(r.data['user']);
                                  setState((){});
                                },
                                onUnregister: (uid){
                                  event.data["players_count"] -= 1;
                                  event.data['user_signups'].remove(uid);
                                  setState((){});
                                }
                              )
                            )
                          ],
                        ),
                      ],
                    )
                  ),
                ),
              );
            })
        ],
      ),
    );
  }
}