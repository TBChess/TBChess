import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:tbchessapp/main.dart';
import 'package:tbchessapp/widgets/event_datetime.dart';
import 'package:tbchessapp/utils/events.dart';
import 'package:tbchessapp/widgets/event_registerbutton.dart';
import 'package:tbchessapp/widgets/event_vs.dart';
import 'package:tbchessapp/widgets/countdown_timer.dart';
import 'package:tbchessapp/widgets/event_game_list.dart';
import 'package:tbchessapp/widgets/event_leaderboard.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tbchessapp/config.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage(this.eventId, {super.key});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  var _loading = true;
  var _startingEvent = false;
  var _subscribedEvent = false;
  var _subscribedSignups = false;
  var _subscribedGames = false;
  var _lastRefresh = 0;

  RecordModel? _event;
  RecordModel? _venue;
  List<RecordModel>? _signups;
  List<RecordModel>? _games;

  Future<void> _startEvent() async{
    try{
      if (mounted){
        if (await context.showConfirmDialog("Are all players here? Make sure to remove any missing player before starting.", confirmText: "Let's go!")){
          setState(() {
            _startingEvent = true;      
          });

          await pb.send("/api/tbchess/event/${_event!.id}/start", method: "POST");
        }
      }
    } on ClientException catch (error){
      if (mounted){
        context.showNetworkError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _startingEvent = false;
        });
      }
    }
  }

  String generateInviteCode(){
    final now = DateTime.now().toIso8601String();
    final bytes = utf8.encode(now);
    return base64.encode(bytes);
  }
  
  void _showQRCodeDialog() {
    final c = getConfig();

    final eventUrl = '${c["APP_URL"]}/#/event/${widget.eventId}?invite=${generateInviteCode()}'; // Replace with your actual domain
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share Invite'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // QR Code
                Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.white, width: 2),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: eventUrl,
                    padding: EdgeInsets.zero,
                    version: QrVersions.auto,
                    size: 280.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                
                // URL Text Field
                TextFormField(
                  initialValue: eventUrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: '',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: eventUrl));
                        context.showSnackBar("URL copied to clipboard!");
                      },
                      tooltip: 'Copy URL',
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),

              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _getEvent({bool background = false, bool ignoreTime = false}) async {
    if (background){
      // Check last time we've updated
      if (!ignoreTime) if (DateTime.now().millisecondsSinceEpoch - _lastRefresh < 10000) return;
    }else{
      setState(() {
        _loading = true;
      });
    }
    
    _lastRefresh = DateTime.now().millisecondsSinceEpoch;

    try {
      _event = await pb.collection("events").getOne(widget.eventId, 
        expand: "venue");
      _venue = _event!.get<RecordModel>("expand.venue");

      Future<void> fetchSignups() async {
        _signups = await pb.collection("event_signups_list").getFullList(
          sort: 'updated',
          filter: 'event="${widget.eventId}"',
        );
      }

      Future<void> fetchGames() async {
        _games = await pb.collection("games_list").getFullList(
          sort: 'round',
          filter: 'event="${widget.eventId}"',
        );
      }

      await Future.wait([
        fetchSignups(),
        fetchGames(),
      ]);

      // If the event has started, but the user is not logged-in,
      // its session probably has expired. Make them log back in
      bool started = _event!.getBoolValue("started");
      bool finished = _event!.getBoolValue("finished");

      if (mounted && (started && !finished) && !pb.authStore.isValid){
        context.setNextPage("/event/${widget.eventId}");
        context.goAuthPage();
        return;
      }
      
      // If background, we don't want to re-subscribe
      if (background) return;

      List<Future<UnsubscribeFunc>> f = [];

      if (!_subscribedEvent){
        f.add(pb.collection('events').subscribe(_event!.id, (e) {
          if (!_subscribedEvent || !mounted) return;
          _event = e.record;
          _venue = _event!.get<RecordModel>("expand.venue");
          setState((){});
        }, expand: "venue"));
        _subscribedEvent = true;
      }

      if (!_subscribedSignups){
        f.add(pb.collection('event_signups').subscribe("*", (e) async {
          if (!_subscribedSignups || !mounted) return;
          await fetchSignups();
          setState((){});
        }, filter: 'event="${widget.eventId}"'));
        _subscribedSignups = true;
      }

      if (!_subscribedGames){
        f.add(pb.collection('games').subscribe("*", (e) async {
          if (!_subscribedGames || !mounted) return;
          await fetchGames();
          setState((){});
        }, filter: 'event="${widget.eventId}"'));
        _subscribedGames = true;
      }

      await Future.wait(f);

    } on ClientException catch (error){
      if (mounted){
        context.showNetworkError(error, title: "Cannot find event");
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  late final _onFocus;
  void onFocus(web.Event e) {
    if (!_loading){
      // App resumed
      _getEvent(background: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _getEvent();
    if (kIsWeb){
      _onFocus = onFocus.toJS;
      web.window.addEventListener("focus", _onFocus);
    }
  }

  @override
  void deactivate(){
    if (_subscribedEvent && _event != null){
      pb.collection('events').unsubscribe(_event!.id);
      _subscribedEvent = false;
    }
    if (_subscribedSignups && _event != null){
      pb.collection('event_signups').unsubscribe("*");
      _subscribedSignups = false;
    }
    if (_subscribedGames && _event != null){
      pb.collection('games').unsubscribe("*");
      _subscribedGames = false;
    }

    if (kIsWeb){
      web.window.removeEventListener("focus", _onFocus);
    }
    super.deactivate();
  }

    Widget _buildInfoItem(IconData icon, String label, String value, { bool multiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: multiline ? null : 1,
          overflow: multiline ? null : TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading){
      return Scaffold(
        appBar: AppBar(
          title: Text("Loading..."), 
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.setPageLoadRedirected();
              context.go('/events');
            },
          ),
        ),      
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          children: [
            const Center(child: CircularProgressIndicator())
          ]
        ),
      );
    }

    final venue = _venue!;
    final event = _event!;
    final userId = pb.authStore.record?.id;
    final isLoggedIn = pb.authStore.isValid;

    String venueLogoUrl = pb.files.getUrl(_venue!, venue.getStringValue("logo")).toString();
    bool venueByob = venue.getBoolValue("byob");
    bool isOwner = pb.authStore.isValid && event.getStringValue('owner') == userId;
    // bool ownerSignedUp = _signups!.where((signup) => signup.data['user'] == event['owner']).isNotEmpty;
    bool isSignedUp = _signups!.where((signup) => signup.data['user'] == userId).isNotEmpty;
    bool canStartEvent = isOwner;// || (!ownerSignedUp && isSignedUp);
    bool started = event.getBoolValue("started");
    bool finished = event.getBoolValue("finished");
    int currentRound = event.getIntValue("current_round");
    String prizes = event.getStringValue("prizes");
    String roundText = "Round $currentRound";
    if (currentRound == event.getIntValue("rounds")){
      roundText = "Final Round";
    }


    List<RecordModel> userGames;
    List<RecordModel>? otherRoundGames;
    RecordModel? userCurrentGame;

    if (_games != null){
      userGames = _games!.where((g) => g.getStringValue("white") == userId || g.getStringValue("black") == userId).toList();
      for (RecordModel g in userGames){
        if (g.getIntValue("round") == currentRound){
          userCurrentGame = g;
          break;
        }
      }

      otherRoundGames = _games!.where((g) => g.getIntValue("round") == currentRound && (g.getStringValue("white") != userId && g.getStringValue("black") != userId )).toList();
    }

    
    return Scaffold(
      appBar: AppBar(
        title: Text(getEventTitle(event.data)), 
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.setPageLoadRedirected();
            context.go('/events');
          },
        ),
        actions: [
            Padding(
            padding: const EdgeInsets.only(right: 12),
              child: !started || !isLoggedIn ? IconButton(
                  icon: const Icon(Icons.qr_code, size: 32),
                  onPressed: () {
                    _showQRCodeDialog();
                  },
                ) : IconButton(
                    icon: const Icon(Icons.account_circle, size: 32),
                    onPressed: () {
                       context.clearPageLoadRedirected();
                       context.go('/account');
                    },
              ),
          ),
        ],
      ),      
      body: RefreshIndicator(onRefresh: () async {
        await _getEvent(background: true, ignoreTime: true);
      }, child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!finished) ...[const SizedBox(height: 16), Center(child: Card(
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Center(
                            child: SvgPicture.asset(
                              assetImagePath('images/swords.svg'),
                              semanticsLabel: 'Swords',
                              allowDrawingOutsideViewBox: true,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                              height: 32,
                            )
                          ),
                          
                          started ? 
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Center(child: Text(
                                    roundText,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                                  const SizedBox(height: 16),

                                  if (userCurrentGame != null) ...[EventVS(userCurrentGame), const SizedBox(height: 16)],
                                  if (otherRoundGames != null) EventGameList(otherRoundGames, isOwner: isOwner),

                                ],
                              ),
                            )

                          // not started yet
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: CountdownTimer(
                              eventDate: event.getStringValue('event_date'),
                              endWidget: canStartEvent ? 
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  minimumSize: const Size(180, 50),
                                ),
                                onPressed: _startingEvent ? null : () => _startEvent(),
                                child: _startingEvent 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 3)
                                    )
                                  : Text("Start Battle", style: TextStyle(fontSize: 18),)
                              )
                              : Text(
                                "Waiting to start the battle",
                                style: Theme.of(context).textTheme.labelLarge
                              ),
                            ),
                          ),
                      ],
                    ),
                    ),
                ))],
                
                const SizedBox(height: 16),

                // Registration / leaderboard

                if (started && _games != null)
                  EventLeaderboard(_games!, title: finished ? "Results" : "Standings")
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.groups, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Players',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_signups != null && _signups!.isNotEmpty)
                            ...(_signups!.map((signup) {
                            final username = signup.get<String>('username');
                            final elo = signup.get<double>('elo').round();
                            final hideElo = pb.authStore.isValid && pb.authStore.record!.getBoolValue("hide_elo");

                            return InkWell(
                              onTap: () {
                                print('Tapped on user: $username');
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
                                  ],
                                ),
                              ),
                            );
                            }).toList())
                          else if (_signups != null && _signups!.isEmpty)
                            const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No players registered yet.',
                              style: TextStyle(
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            ),
                          const SizedBox(height: 16),
                          Center(child: EventRegisterButton(_event!, isSignedUp, venueByob, 
                                          hideWhenStarted: true,
                                          cancelLabel: true, ))
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                                // Date and time
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event title at the top
                        Text(
                          venue.getStringValue("name"),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Logo and content section
                        Column(children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo section
                              venueLogoUrl.isNotEmpty
                                ? Image.network(venueLogoUrl, width: 92, height: 92)
                                : Icon(Icons.event, size: 72, color: Colors.blueAccent),
                              const SizedBox(width: 16),
                              // Content section
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Date and time section
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.only(left: 3), 
                                      child: EventDateTime(
                                        event.getStringValue('event_date'),
                                        spacing: 8
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Location section
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                      const Icon(Icons.location_on, color: Colors.red),
                                      const SizedBox(width: 4),
                                      Text(
                                        getVenueAddress(venue.data),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis
                                      ),
                                      ],
                                    ),
                                  ],
                                ),
                            ]
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // First row of details
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.repeat,
                                      'Rounds',
                                      '${event.getIntValue("rounds")}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.timer,
                                      'Time Control',
                                      event.getStringValue('time_control'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Second row of details
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.people_outline,
                                      'Max Players',
                                      '${event.getIntValue('max_players')}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.dashboard,
                                      'Chess Boards',
                                      venueByob ? 'Bring own' : 'Provided',
                                    ),
                                  ),
                                ],
                              ),

                              
                              if (prizes.isNotEmpty) ...[const SizedBox(height: 12), Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.emoji_events,
                                      'Prizes',
                                      prizes,
                                      multiline: true
                                    ),
                                  )
                                ],
                              ),],
                            ],                            
                          ),
                        ),
                        ]),
                      ],
                    ),
                  ),
                ),            
              ],
            ),
        ],
      ),
      ),
    );
  }
}