import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'oxigen_constants.dart';
import 'page_base.dart';

class ControllerDataPage extends PageBase {
  const ControllerDataPage({super.key}) : super(title: 'Controller data', body: const ControllerData());

  @override
  State<PageBase> createState() => _ControllerDataPageState();
}

class _ControllerDataPageState<SettingsPage> extends PageBaseState<PageBase> {}

class ControllerData extends StatelessWidget {
  const ControllerData({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, model, child) {
      final carControllerPairs = model.carControllerPairs();
      if (carControllerPairs.isEmpty) {
        return const Center(child: Text('There are no connected controllers'));
      } else {
        return FittedBox(
          child: DataTable(
              columnSpacing: 10,
              columns: const [
                DataColumn(label: Text('Id'), numeric: true),
                DataColumn(label: Text('Throttle')),
                DataColumn(label: Text('Up button')),
                DataColumn(label: Text('Down button')),
                DataColumn(label: Text('Round button')),
                DataColumn(label: Text('Track call')),
                DataColumn(label: Text('Battery')),
                DataColumn(label: Text('Firmware'), numeric: true),
              ],
              rows: carControllerPairs
                  .map((x) => DataRow(cells: [
                        DataCell(Text(x.key.toString())),
                        DataCell(Row(
                          children: [
                            SizedBox(
                                width: 25,
                                child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(x.value.rx.triggerMeanValue.toString()))),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 300,
                              child: LinearProgressIndicator(value: x.value.rx.triggerMeanValue / 127),
                            ),
                          ],
                        )),
                        DataCell(x.value.rx.arrowUpButton == OxigenRxArrowUpButton.buttonPressed
                            ? const Icon(Icons.arrow_upward)
                            : const Text('')),
                        DataCell(x.value.rx.arrowDownButton == OxigenRxArrowDownButton.buttonPressed
                            ? const Icon(Icons.arrow_downward)
                            : const Text('')),
                        DataCell(x.value.rx.roundButton == OxigenRxRoundButton.buttonPressed
                            ? const Icon(Icons.radio_button_checked)
                            : const Text('')),
                        DataCell(x.value.rx.trackCall == OxigenRxTrackCall.yes
                            ? const Icon(Icons.flag, color: Colors.red)
                            : const Text('')),
                        DataCell(x.value.rx.controllerBatteryLevel == OxigenRxControllerBatteryLevel.ok
                            ? const Icon(Icons.battery_full)
                            : const Icon(
                                Icons.battery_alert,
                                color: Colors.red,
                              )),
                        DataCell(Text(x.value.rx.controllerFirmwareVersion.toString())),
                      ]))
                  .toList()),
        );
      }
    });
  }
}
