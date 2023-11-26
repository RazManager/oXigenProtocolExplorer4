import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'oxigen_constants.dart';
import 'page_base.dart';


// Car data view

class CarDataPage extends PageBase {
  const CarDataPage({super.key}) : super(title: 'Car data', body: const CarData());

  @override
  State<PageBase> createState() => _CarDataPageState();
}

class _CarDataPageState<SettingsPage> extends PageBaseState<PageBase> {}

class CarData extends StatelessWidget {
  const CarData({super.key});

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
                DataColumn(label: Text('On track')),
                DataColumn(label: Text('Pitlane')),
                DataColumn(label: Text('Car reset')),
                DataColumn(label: Text('Link reset')),
                DataColumn(label: Text('Firmware'), numeric: true),
              ],
              rows: carControllerPairs
                  .map((x) => DataRow(cells: [
                        DataCell(Text(x.key.toString())),
                        DataCell(x.value.rx.carOnTrack == OxigenRxCarOnTrack.carIsOnTheTrack
                            ? const Icon(Icons.no_crash)
                            : const Icon(Icons.car_crash, color: Colors.red)),
                        DataCell(x.value.rx.carPitLane == OxigenRxCarPitLane.carIsInThePitLane
                            ? const Icon(Icons.car_repair)
                            : const Text('')),
                        DataCell(Badge(
                            label: x.value.rx.carResetCount == 0 ? null : Text(x.value.rx.carResetCount.toString()),
                            child: const Icon(Icons.restart_alt))),
                        DataCell(Badge(
                            label: x.value.rx.controllerCarLinkCount == 0
                                ? null
                                : Text(x.value.rx.controllerCarLinkCount.toString()),
                            child: const Icon(Icons.link))),
                        DataCell(Text(x.value.rx.carFirmwareVersion.toString())),
                      ]))
                  .toList()),
        );
      }
    });
  }
}
