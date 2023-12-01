import 'dart:async';
//import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

//import 'package:syncfusion_flutter_charts/charts.dart';
//import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import 'app_model.dart';
import 'oxigen_constants.dart';
//import 'serial_port_worker.dart' hide CarControllerPair;
import 'page_base.dart';
import 'race_state_bottom_navigation_bar.dart';

class RaceSession extends StatefulWidget {
  const RaceSession({super.key});

  @override
  State<RaceSession> createState() => _RaceSessionState();
}

class _RaceSessionState extends State<RaceSession> {
  StreamSubscription<String>? exceptionStreamSubscription;
  final scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    exceptionStreamSubscription = context.read<AppModel>().exceptionStreamController.stream.listen((message) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 10)));
    });
  }

  @override
  void dispose() async {
    super.dispose();
    if (exceptionStreamSubscription != null) {
      await exceptionStreamSubscription!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const AppNavigationRail(),
      Expanded(
        child: Consumer<AppModel>(builder: (context, model, child) {
          final carControllerPairs = model.carControllerPairs();
          if (carControllerPairs.isEmpty) {
            return Scaffold(
                appBar: AppBar(title: const Text('Race session')),
                body: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Align(alignment: Alignment.topCenter, child: Text('There are no connected controllers')),
                ));
          } else {
            return DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Race session'),
                  bottom: const TabBar(tabs: <Tab>[
                    Tab(text: 'Race settings'),
                    Tab(text: 'Race leaderboard'),
                    Tab(text: 'Race driverboard')
                  ]),
                ),
                bottomNavigationBar:
                    RaceStateBottomNaviagationBar(value: model.txRaceState, setValue: model.oxigenTxRaceStateSet),
                body: TabBarView(children: <Widget>[RaceSettings(), RaceLeaderBoard(model: model), RaceSettings()]),
              ),
            );
          }
        }),
      )
    ]);
  }
}

class RaceSettings extends StatelessWidget {
  const RaceSettings({super.key});
  @override
  Widget build(BuildContext context) {
    return const Text('Race settings...');
  }
}

class RaceLeaderBoard extends StatelessWidget {
  const RaceLeaderBoard({super.key, required this.model});
  final AppModel model;

  @override
  Widget build(BuildContext context) {
    final carControllerPairs = model.carControllerPairs().sorted((a, b) {
      if (a.value.rx.calculatedLaps == null && b.value.rx.calculatedLaps == null) return 0;
      if (a.value.rx.calculatedLaps == null) return 1;
      if (b.value.rx.calculatedLaps == null) return -1;
      var result = -a.value.rx.calculatedLaps!.compareTo(b.value.rx.calculatedLaps!);
      if (result == 0) {
        if (a.value.rx.previousLapRaceTimer == null && b.value.rx.previousLapRaceTimer == null) return 0;
        if (a.value.rx.previousLapRaceTimer == null) return 1;
        if (b.value.rx.previousLapRaceTimer == null) return -1;
        return a.value.rx.previousLapRaceTimer!.compareTo(b.value.rx.previousLapRaceTimer!);
      }
      return result;
    });
    return Scrollbar(
        controller: context.findAncestorStateOfType<_RaceSessionState>()!.scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
            controller: context.findAncestorStateOfType<_RaceSessionState>()!.scrollController,
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DataTable(
                    columnSpacing: 10,
                    columns: const [
                      DataColumn(label: Text('Pos'), numeric: true),
                      DataColumn(label: Text('Id'), numeric: true),
                      DataColumn(label: Text('Laps'), numeric: true),
                      DataColumn(label: Text('Lap time'), numeric: true),
                      DataColumn(label: Text('Fastest lap time'), numeric: true),
                      DataColumn(label: Text('Fuel/energy consumption latest 10 laps')),
                      DataColumn(label: Text('Fuel/energy level')),
                      DataColumn(label: Text('Laps until empty'), numeric: true),
                      DataColumn(label: Text('')),
                    ],
                    rows: carControllerPairs
                        .mapIndexed((i, x) => DataRow(cells: [
                              DataCell(Text((i + 1).toString())),
                              DataCell(Text(x.key.toString())),
                              DataCell(
                                  Text(x.value.rx.calculatedLaps == null ? '' : x.value.rx.calculatedLaps.toString())),
                              DataCell(Text(x.value.rx.calculatedLapTimeSeconds == null
                                  ? ''
                                  : x.value.rx.calculatedLapTimeSeconds!.toStringAsFixed(2))),
                              DataCell(Text(x.value.rx.fastestLapTime == null
                                  ? ''
                                  : x.value.rx.fastestLapTime!.toStringAsFixed(2))),
                              DataCell(Container(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  width: 300,
                                  child: x.value.rx.lapTriggerMeanValueMilliSeconds.isEmpty ||
                                          x.value.rx.calculatedLaps == null ||
                                          x.value.rx.calculatedLaps! <= 1
                                      ? const Text('')
                                      : SfSparkBarChart(
                                          data: x.value.rx.lapTriggerMeanValueMilliSeconds.entries
                                              .map((entry) => entry.value)
                                              .toList(),
                                          color: Colors.indigo,
                                          axisLineColor: Colors.transparent,
                                        ))),
                              DataCell(SizedBox(
                                width: 300,
                                child:
                                    LinearProgressIndicator(value: x.value.rx.triggerMeanValueMilliSecondsLevel / 100),
                              )),
                              DataCell(Text(x.value.rx.calculatedLaps == null || x.value.rx.calculatedLaps! < 1
                                  ? ''
                                  : (x.value.rx.triggerMeanValueMilliSecondsLevel /
                                          x.value.rx.lapTriggerMeanValueMilliSeconds[x.value.rx.calculatedLaps! - 1]!)
                                      .toStringAsFixed(2))),
                              DataCell(Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (x.value.rx.carOnTrack == OxigenRxCarOnTrack.carIsNotOnTheTrack)
                                    const Icon(Icons.car_crash, color: Colors.red),
                                  if (x.value.rx.carPitLane == OxigenRxCarPitLane.carIsInThePitLane)
                                    const Icon(Icons.car_repair),
                                  if (x.value.rx.trackCall == OxigenRxTrackCall.yes) const Icon(Icons.flag),
                                  if (x.value.rx.controllerBatteryLevel == OxigenRxControllerBatteryLevel.low)
                                    const Icon(Icons.battery_alert, color: Colors.red),
                                ],
                              ))
                            ]))
                        .toList()))));
  }
}
