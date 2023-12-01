import 'package:flutter/material.dart';

import 'oxigen_constants.dart';

class RaceStateBottomNaviagationBar extends StatelessWidget {
  const RaceStateBottomNaviagationBar({super.key, this.value, required this.setValue});
  final OxigenTxRaceState? value;
  final Function(OxigenTxRaceState) setValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        FilledButton.tonal(
          onPressed: value == OxigenTxRaceState.running ? null : () => setValue(OxigenTxRaceState.running),
          child: const Icon(Icons.play_arrow),
        ),
        const SizedBox(width: 16),
        FilledButton.tonal(
          onPressed: value == OxigenTxRaceState.paused ? null : () => setValue(OxigenTxRaceState.paused),
          child: const Icon(Icons.pause),
        ),
        const SizedBox(width: 16),
        FilledButton.tonal(
          onPressed: value == OxigenTxRaceState.paused ? null : () => setValue(OxigenTxRaceState.stopped),
          child: const Icon(Icons.stop),
        ),
      ]),
    );
  }
}
