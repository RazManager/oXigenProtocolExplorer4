import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'command_slider.dart';
import 'oxigen_constants.dart';
import 'app_model.dart';
import 'page_base.dart';
import 'race_state_segmented_button.dart';

class SettingsPage extends PageBase {
  const SettingsPage({super.key}) : super(title: 'Settings', body: const Settings());

  @override
  State<PageBase> createState() => _SettingsPageState();
}

class _SettingsPageState<SettingsPage> extends PageBaseState<PageBase> {}

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, model, child) {
      if (model.serialPortList.isEmpty) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Cannot find any serial ports.'),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: () => model.serialPortRefresh(), child: const Text('Refresh serial ports')),
        ]);
      } else {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Serial port *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              DropdownButton<String>(
                  value: model.serialPortGet(),
                  items: model.serialPortList
                      .map<DropdownMenuItem<String>>(
                        (x) => DropdownMenuItem<String>(value: x.name, child: Text(x.description)),
                      )
                      .toList(),
                  onChanged: (value) => model.serialPortSet(value!)),
              const SizedBox(width: 16),
              FilledButton.tonal(onPressed: () => model.serialPortRefresh(), child: const Text('Refresh')),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Baud rate *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButton<int>(
              value: model.baudRate,
              items: model.baudRates
                  .map<DropdownMenuItem<int>>(
                    (x) => DropdownMenuItem<int>(value: x, child: Text(x.toString())),
                  )
                  .toList(),
              onChanged: (value) => model.baudRateSet(value!)),
          const SizedBox(height: 8),
          Table(
            columnWidths: const <int, TableColumnWidth>{
              0: IntrinsicColumnWidth(),
              1: IntrinsicColumnWidth(),
              2: IntrinsicColumnWidth(),
            },
            children: [
              const TableRow(children: [
                Text(
                  'Pitlane lap counting *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 16),
                Text(
                  'Pitlane lap trigger placement *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ]),
              const TableRow(
                children: [SizedBox(height: 8), SizedBox(width: 16), SizedBox(height: 8)],
              ),
              TableRow(children: [
                SegmentedButton<OxigenTxPitlaneLapCounting>(
                  segments: const [
                    ButtonSegment<OxigenTxPitlaneLapCounting>(
                        value: OxigenTxPitlaneLapCounting.enabled, label: Text('Enabled')),
                    ButtonSegment<OxigenTxPitlaneLapCounting>(
                        value: OxigenTxPitlaneLapCounting.disabled, label: Text('Disabled')),
                  ],
                  emptySelectionAllowed: true,
                  selected: model.txPitlaneLapCounting == null ? {} : {model.txPitlaneLapCounting!},
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      model.oxigenTxPitlaneLapCountingSet(selected.first);
                    }
                  },
                ),
                const SizedBox(width: 16),
                SegmentedButton<OxigenTxPitlaneLapTrigger>(
                  segments: const [
                    ButtonSegment<OxigenTxPitlaneLapTrigger>(
                        value: OxigenTxPitlaneLapTrigger.pitlaneEntry, label: Text('Pitlane entry')),
                    ButtonSegment<OxigenTxPitlaneLapTrigger>(
                        value: OxigenTxPitlaneLapTrigger.pitlaneExit, label: Text('Pitlane exit')),
                  ],
                  emptySelectionAllowed: true,
                  selected: model.txPitlaneLapTrigger == null ? {} : {model.txPitlaneLapTrigger!},
                  onSelectionChanged: (model.txPitlaneLapCounting == null ||
                          model.txPitlaneLapCounting == OxigenTxPitlaneLapCounting.disabled)
                      ? null
                      : (selected) {
                          if (selected.isNotEmpty) {
                            model.oxigenPitlaneLapTriggerModeSet(selected.first);
                          }
                        },
                ),
              ])
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Race state *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RaceStateSegmentedButton(value: model.txRaceState, setValue: model.oxigenTxRaceStateSet),
          const SizedBox(height: 16),
          const Text(
            'Maximum speed (TX byte 1) *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          CommandSlider(max: 255, id: 0, value: model.maximumSpeed, setValue: model.oxigenMaximumSpeedSet),
          const SizedBox(height: 16),
          const Text(
            'Controller timeout (s) *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          CommandSlider(max: 255, id: 0, value: model.rxControllerTimeout, setValue: model.controllerTimeoutSet),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.tonal(
                  onPressed: (model.serialPortCanOpen()) ? () => model.serialPortOpen() : null,
                  child: const Text('Open serial port and start communication')),
              const SizedBox(width: 16),
              FilledButton.tonal(
                  onPressed: (model.serialPortCanClose()) ? () => model.serialPortClose() : null,
                  child: const Text('Close serial port')),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Dongle firmware',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
              height: 16,
              child: Text(model.dongleFirmwareVersion != null ? model.dongleFirmwareVersion!.toString() : '')),
        ]);
      }
    });
  }
}
