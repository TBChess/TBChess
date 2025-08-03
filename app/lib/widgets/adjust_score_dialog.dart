import 'package:flutter/material.dart';

enum MatchAdjustmentResult { whiteWon, blackWon, draw }

class AdjustScoreDialog extends StatelessWidget {
  final Function(MatchAdjustmentResult) onResultSelected;
  final String title;

  const AdjustScoreDialog({
    super.key,
    required this.onResultSelected,
    this.title = "Adjust Score"
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          // I Won button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onResultSelected(MatchAdjustmentResult.whiteWon);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white38,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              icon: const Icon(Icons.thumb_up, size: 20),
              label: const Text(
                'White Won',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // I Lost button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onResultSelected(MatchAdjustmentResult.blackWon);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black38,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              icon: const Icon(Icons.thumb_up, size: 20),
              label: const Text(
                'Black Won',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Draw button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onResultSelected(MatchAdjustmentResult.draw);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              icon: const Icon(Icons.handshake, size: 20),
              label: const Text(
                'Draw',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  // Static method to show the dialog
  static Future<void> show(
    BuildContext context, {
    required Function(MatchAdjustmentResult) onResultSelected,
    String title = "Adjust Score",
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Allows dismissing by tapping outside
      builder: (BuildContext context) {
        return AdjustScoreDialog(onResultSelected: onResultSelected, title: title);
      },
    );
  }
}
