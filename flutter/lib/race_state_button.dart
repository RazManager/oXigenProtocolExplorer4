import 'package:flutter/material.dart';

import 'oxigen_constants.dart';

class RaceStateButton extends StatelessWidget {
  const RaceStateButton({super.key, this.value, required this.setValue});
  final OxigenTxRaceState? value;
  final Function(OxigenTxRaceState) setValue;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<OxigenTxRaceState>(
      segments: const [
        ButtonSegment<OxigenTxRaceState>(value: OxigenTxRaceState.running, label: Text('Running')),
        ButtonSegment<OxigenTxRaceState>(value: OxigenTxRaceState.paused, label: Text('Paused')),
        ButtonSegment<OxigenTxRaceState>(value: OxigenTxRaceState.stopped, label: Text('Stopped')),
        ButtonSegment<OxigenTxRaceState>(
            value: OxigenTxRaceState.flaggedLcEnabled, label: Text('Flagged (LC enabled)')),
        ButtonSegment<OxigenTxRaceState>(
            value: OxigenTxRaceState.flaggedLcDisabled, label: Text('Flagged (LC disabled)')),
      ],
      emptySelectionAllowed: true,
      selected: value == null ? {} : {value!},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) {
          setValue(selected.first);
        }
      },
    );
  }
}
