import 'package:flutter/material.dart';

enum MatchResult { Won, Lost, Draw }

class ReportScoreDialog extends StatelessWidget {
  final Function(MatchResult) onResultSelected;
  final String title;

  const ReportScoreDialog({
    super.key,
    required this.onResultSelected,
    this.title = "Report Score"
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
                onResultSelected(MatchResult.Won);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              icon: const Icon(Icons.thumb_up, size: 20),
              label: const Text(
                'I Won',
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
                onResultSelected(MatchResult.Lost);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              icon: const Icon(Icons.thumb_down, size: 20),
              label: const Text(
                'I Lost',
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
                onResultSelected(MatchResult.Draw);
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
    required Function(MatchResult) onResultSelected,
    String title = "Report Score",
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Allows dismissing by tapping outside
      builder: (BuildContext context) {
        return ReportScoreDialog(onResultSelected: onResultSelected, title: title);
      },
    );
  }
}
