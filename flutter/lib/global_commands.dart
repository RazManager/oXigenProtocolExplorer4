import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'command_slider.dart';
import 'oxigen_constants.dart';
import 'app_model.dart';
import 'page_base.dart';
import 'race_state_segmented_button.dart';

class GlobalCommandsPage extends PageBase {
  const GlobalCommandsPage({super.key}) : super(title: 'Global commands', body: const GlobalCommands());

  @override
  State<PageBase> createState() => _GlobalCommandsPageState();
}

class _GlobalCommandsPageState<GlobalCommandsPage> extends PageBaseState<PageBase> {}

class GlobalCommands extends StatelessWidget {
  const GlobalCommands({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, model, child) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        const Text(
          'Maximum speed (global command)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        CommandSlider(
            max: 255,
            id: 0,
            value: model.globalCarControllerPairTx().maximumSpeed,
            setValue: model.oxigenTxMaximumSpeedSet),
        const Text(
          'Minimum speed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        CommandSlider(
            max: 63,
            id: 0,
            value: model.globalCarControllerPairTx().minimumSpeed,
            setValue: model.oxigenTxMinimumSpeedSet),
        const Text(
          'Pitlane speed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        CommandSlider(
            max: 255,
            id: 0,
            value: model.globalCarControllerPairTx().pitlaneSpeed,
            setValue: model.oxigenTxPitlaneSpeedSet),
        const Text(
          'Maximum brake',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        CommandSlider(
            max: 255,
            id: 0,
            value: model.globalCarControllerPairTx().maximumBrake,
            setValue: model.oxigenTxMaximumBrakeSet),
        Table(
          columnWidths: const <int, TableColumnWidth>{
            0: IntrinsicColumnWidth(),
            1: IntrinsicColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(children: [
              const Text(
                'Force lane change up  ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                thumbIcon: MaterialStateProperty.resolveWith<Icon?>((Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Icon(Icons.arrow_upward);
                  }
                  if (model.globalCarControllerPairTx().forceLcUp != null) {
                    return const Icon(Icons.close);
                  }
                  return const Icon(Icons.question_mark);
                }),
                value: model.globalCarControllerPairTx().forceLcUp ?? false,
                onChanged: (value) => model.oxigenTxForceLcUpSet(0, value),
              ),
            ]),
            TableRow(children: [
              const Text(
                'Force lane change down  ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                thumbIcon: MaterialStateProperty.resolveWith<Icon?>((Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Icon(Icons.arrow_downward);
                  }
                  if (model.globalCarControllerPairTx().forceLcDown != null) {
                    return const Icon(Icons.close);
                  }
                  return const Icon(Icons.question_mark);
                }),
                value: model.globalCarControllerPairTx().forceLcDown ?? false,
                onChanged: (value) => model.oxigenTxForceLcDownSet(0, value),
              ),
            ])
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Transmission power',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<OxigenTxTransmissionPower>(
          segments: const [
            ButtonSegment<OxigenTxTransmissionPower>(value: OxigenTxTransmissionPower.dBm18, label: Text('-18 dBm')),
            ButtonSegment<OxigenTxTransmissionPower>(value: OxigenTxTransmissionPower.dBm12, label: Text('-12 dBm')),
            ButtonSegment<OxigenTxTransmissionPower>(value: OxigenTxTransmissionPower.dBm6, label: Text('-6 dBm')),
            ButtonSegment<OxigenTxTransmissionPower>(value: OxigenTxTransmissionPower.dBm0, label: Text('0 dBm')),
          ],
          emptySelectionAllowed: true,
          selected: model.globalCarControllerPairTx().transmissionPower == null
              ? {}
              : {model.globalCarControllerPairTx().transmissionPower!},
          onSelectionChanged: (selected) {
            if (selected.isNotEmpty) {
              model.oxigenTxTransmissionPowerSet(0, selected.first);
            }
          },
        ),
      ]);
    });
  }
}
