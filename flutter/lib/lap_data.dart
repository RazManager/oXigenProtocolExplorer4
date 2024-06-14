import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'page_base.dart';
import 'race_state_segmented_button.dart';

class LapDataPage extends PageBase {
  const LapDataPage({super.key}) : super(title: 'Lap data', body: const LapData());

  @override
  State<PageBase> createState() => _LapDataPageState();
}

class _LapDataPageState<SettingsPage> extends PageBaseState<PageBase> {}

class LapData extends StatelessWidget {
  const LapData({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, model, child) {
      final carControllerPairs = model.carControllerPairs();
      if (carControllerPairs.isEmpty) {
        return const Center(child: Text('There are no connected controllers'));
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RaceStateSegmentedButton(value: model.txRaceState, setValue: model.oxigenTxRaceStateSet),
            FittedBox(
              child: DataTable(
                  columnSpacing: 10,
                  columns: const [
                    DataColumn(label: Text('Id'), numeric: true),
                    DataColumn(label: Text('Dongle lap timer (cs)'), numeric: true),
                    DataColumn(label: Text('Dongle lap time (cs)'), numeric: true),
                    DataColumn(label: Text('Dongle lap time (s)'), numeric: true),
                    DataColumn(label: Text('Dongle delay (cs)'), numeric: true),
                    DataColumn(label: Text('Calc. lap time (s)'), numeric: true),
                    DataColumn(label: Text('Dongle laps'), numeric: true),
                    DataColumn(label: Text('Missed dongle laps'), numeric: true),
                    DataColumn(label: Text('Calc. laps'), numeric: true),
                  ],
                  rows: carControllerPairs
                      .map((x) => DataRow(cells: [
                            DataCell(Text(x.key.toString())),
                            DataCell(Text(x.value.rx.dongleLapRaceTimer.toString())),
                            DataCell(Text(x.value.rx.dongleLapTime.toString())),
                            DataCell(Text(x.value.rx.dongleLapTimeSeconds.toStringAsFixed(2).toString())),
                            DataCell(Text(x.value.rx.dongleLapTimeDelay.toString())),
                            DataCell(Text(x.value.rx.calculatedLapTimeSeconds == null
                                ? ''
                                : x.value.rx.calculatedLapTimeSeconds!.toStringAsFixed(2))),
                            DataCell(Text(x.value.rx.dongleLaps.toString())),
                            DataCell(Text(x.value.rx.dongleLapsMissed.toString())),
                            DataCell(
                                Text(x.value.rx.calculatedLaps == null ? '' : x.value.rx.calculatedLaps.toString())),
                          ]))
                      .toList()),
            ),
          ],
        );
      }
    });
  }
}
