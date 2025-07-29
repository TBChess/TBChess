import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tbchessapp/utils/date.dart';

class CountdownTimer extends StatefulWidget {
    final String eventDate;
    final Widget endWidget;

    const CountdownTimer({
        super.key,
        required this.eventDate,
        required this.endWidget
    });

    @override
    State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
    late Timer _timer;
    late DateTime _targetDate;
    Duration _duration = Duration.zero;

    @override
    void initState() {
        super.initState();
        _targetDate = parseDateString(widget.eventDate)!;
        // _targetDate = DateTime.now().add(Duration(seconds: 10));
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
        _updateTime();
    }

    @override
    void dispose() {
        _timer.cancel();
        super.dispose();
    }

    void _updateTime() {
        final now = DateTime.now();
        final difference = _targetDate!.difference(now);

        if (difference.isNegative) {
            setState(() {
                _duration = Duration.zero;
            });
            _timer.cancel();
        } else {
            setState(() {
                _duration = difference;
            });
        }
    }

    String _formatNumber(int number) {
        return number.toString().padLeft(2, '0');
    }

    @override
    Widget build(BuildContext context) {
        if (_duration == Duration.zero) {
            return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.endWidget
                ]
            );
        }

        final days = _duration.inDays;
        final hours = _duration.inHours.remainder(24);
        final minutes = _duration.inMinutes.remainder(60);
        final seconds = _duration.inSeconds.remainder(60);

        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                _buildTimeSegment(days, 'DAYS'),
                _buildTimeSegment(hours, 'HOURS'),
                _buildTimeSegment(minutes, 'MINS'),
                _buildTimeSegment(seconds, 'SECS'),
            ],
        );
    }

    Widget _buildTimeSegment(int time, String label) {
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Text(
                        _formatNumber(time),
                        style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
            ),
        );
    }
}
