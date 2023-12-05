import 'package:flutter/material.dart';

import 'app_model.dart';

class TimerHeader extends StatelessWidget {
  const TimerHeader({super.key, required this.model, required this.fontSize});
  final AppModel model;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Table(
      children: [
        TableRow(children: [
          Center(
            child: Text(
              timerFormat(model.dongleLapRaceTimerMax, 100),
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              timerFormat(model.stopwatch.elapsedMilliseconds, 1000),
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          )
        ]),
        const TableRow(children: [Center(child: Text('Dongle race timer')), Center(child: Text('Computer race timer'))])
      ],
    );
  }

  String timerFormat(int value, int secondsFactor) {
    if (value / secondsFactor < 3600) {
      return '${value / secondsFactor ~/ 60}:${((value / secondsFactor) % 60).toInt().toString().padLeft(2, '0')}';
    } else {
      return '${value / secondsFactor ~/ 3600}:${((value / secondsFactor / 60) % 60).toInt().toString().padLeft(2, '0')}:${((value / secondsFactor) % 60).toInt().toString().padLeft(2, '0')}';
    }
  }
}
