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
import 'serial_port_worker.dart' hide CarControllerPair;
import 'page_base.dart';
import 'race_state_bottom_navigation_bar.dart';
import 'timer_header.dart';

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
                body: TabBarView(
                    children: <Widget>[RaceSettings(), RaceLeaderBoard(model: model), RaceDriverBoard(model: model)]),
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
    var carControllerPairs = model.carControllerPairPositions();
    return Column(children: [
      const SizedBox(height: 16),
      TimerHeader(model: model, fontSize: 16),
      Padding(
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
                  .map((x) => DataRow(cells: [
                        DataCell(Text((x.value.position).toString())),
                        DataCell(Text(x.key.toString())),
                        DataCell(Text(x.value.rx.calculatedLaps == null ? '' : x.value.rx.calculatedLaps.toString())),
                        DataCell(Text(x.value.rx.calculatedLapTimeSeconds == null
                            ? ''
                            : x.value.rx.calculatedLapTimeSeconds!.toStringAsFixed(2))),
                        DataCell(Text(
                            x.value.rx.fastestLapTime == null ? '' : x.value.rx.fastestLapTime!.toStringAsFixed(2))),
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
                          child: LinearProgressIndicator(value: x.value.rx.triggerMeanValueMilliSecondsLevel / 100),
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
                  .toList()))
    ]);
  }
}

class RaceDriverBoard extends StatelessWidget {
  const RaceDriverBoard({super.key, required this.model});
  final AppModel model;

  @override
  Widget build(BuildContext context) {
    model.carControllerPairPositions();
    var carControllerPairs = model.carControllerPairs();
    //final colorList = [Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.amber];
    return Column(children: [
      const SizedBox(height: 16),
      TimerHeader(model: model, fontSize: 16),
      Table(border: TableBorder.all(color: Colors.cyan), children: [
        for (int row = 0; row < carControllerPairs.length / 2; row++)
          TableRow(children: [
            for (int column = 0; column < 2; column++)
              row * 2 + column < carControllerPairs.length
                  ? RaceDriverBoardCarController(
                      carControllerPairKv: carControllerPairs.toList()[row * 2 + column],
                      model: model,
                    )
                  : const Text('Missing...'),
          ]),
      ])
    ]);
  }
}

class RaceDriverBoardCarController extends StatelessWidget {
  const RaceDriverBoardCarController({super.key, required this.carControllerPairKv, required this.model});
  final MapEntry<int, CarControllerPair> carControllerPairKv;
  final AppModel model;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        children: [Text("Id ${carControllerPairKv.key}"), Text("Position ${carControllerPairKv.value.position}")],
      ),
      Row(
        children: [
          Column(
            children: [
              SfRadialGauge(
                axes: [
                  RadialAxis(
                    ticksPosition: ElementsPosition.outside,
                    labelsPosition: ElementsPosition.outside,
                    maximum: 255,
                    ranges: [
                      GaugeRange(
                        startValue: rangeMinimumSpeed(carControllerPairKv.value, model.globalCarControllerPairTx()),
                        endValue: rangeMaximumSpeed(
                            carControllerPairKv.value, model.globalCarControllerPairTx(), model.maximumSpeed),
                        color: Colors.green,
                      )
                    ],
                  ),
                  RadialAxis(
                    radiusFactor: 0.7,
                    maximum: 127,
                    pointers: [
                      RangePointer(
                          value: carControllerPairKv.value.rx.triggerMeanValue.toDouble(), color: Colors.indigo)
                    ],
                    annotations: [
                      GaugeAnnotation(
                          angle: 90,
                          positionFactor: 1,
                          widget: Column(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (carControllerPairKv.value.rx.carOnTrack == OxigenRxCarOnTrack.carIsNotOnTheTrack)
                                  const Icon(Icons.car_crash, color: Colors.red),
                                if (carControllerPairKv.value.rx.carPitLane == OxigenRxCarPitLane.carIsInThePitLane)
                                  const Icon(Icons.car_repair),
                                if (carControllerPairKv.value.rx.arrowUpButton == OxigenRxArrowUpButton.buttonPressed)
                                  const Icon(Icons.arrow_upward),
                                if (carControllerPairKv.value.rx.arrowDownButton ==
                                    OxigenRxArrowDownButton.buttonPressed)
                                  const Icon(Icons.arrow_downward),
                                if (carControllerPairKv.value.rx.trackCall == OxigenRxTrackCall.yes)
                                  const Icon(Icons.flag),
                                if (carControllerPairKv.value.rx.controllerBatteryLevel ==
                                    OxigenRxControllerBatteryLevel.low)
                                  const Icon(Icons.battery_alert, color: Colors.red),
                              ],
                            ),
                            Text(
                              carControllerPairKv.value.rx.triggerMeanValue.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 48),
                            ),
                          ]))
                    ],
                  )
                ],
              ),
              const Text("Latest...")
            ],
          ),
          Column(children: [
            SfLinearGauge(minimum: 0, maximum: 100, orientation: LinearGaugeOrientation.vertical, barPointers: [
              LinearBarPointer(
                value: carControllerPairKv.value.rx.triggerMeanValueMilliSecondsLevel,
              )
            ]),
            const Text("Level...")
          ])
        ],
      ),
    ]);
  }

  double rangeMaximumSpeed(
      CarControllerPair carControllerPair, TxCarControllerPair globalCarControllerPairTx, int? maximumSpeed) {
    int result = maximumSpeed ?? 255;

    if (carControllerPair.rx.carPitLane == OxigenRxCarPitLane.carIsNotInThePitLane) {
      if (globalCarControllerPairTx.maximumSpeed != null && globalCarControllerPairTx.maximumSpeed! < result) {
        result = globalCarControllerPairTx.maximumSpeed!;
      } else if (carControllerPair.tx.maximumSpeed != null &&
          (globalCarControllerPairTx.maximumSpeed == null || globalCarControllerPairTx.maximumSpeed == 255) &&
          carControllerPair.tx.maximumSpeed! < result) {
        result = carControllerPair.tx.maximumSpeed!;
      }
    } else {
      if (globalCarControllerPairTx.pitlaneSpeed != null && globalCarControllerPairTx.pitlaneSpeed! < result) {
        result = globalCarControllerPairTx.pitlaneSpeed!;
      } else if (carControllerPair.tx.pitlaneSpeed != null &&
          (globalCarControllerPairTx.pitlaneSpeed == null || globalCarControllerPairTx.pitlaneSpeed == 255) &&
          carControllerPair.tx.pitlaneSpeed! < result) {
        result = carControllerPair.tx.pitlaneSpeed!;
      }
    }

    return result.toDouble();
  }

  double rangeMinimumSpeed(CarControllerPair carControllerPair, TxCarControllerPair globalCarControllerPairTx) {
    int result = 0;

    if (globalCarControllerPairTx.minimumSpeed != null && globalCarControllerPairTx.minimumSpeed! != 0) {
      result = globalCarControllerPairTx.minimumSpeed!;
    } else if (carControllerPair.tx.minimumSpeed != null &&
        (globalCarControllerPairTx.minimumSpeed == null || globalCarControllerPairTx.minimumSpeed == 0)) {
      result = carControllerPair.tx.minimumSpeed!;
    }

    return result.toDouble() * 2;
  }
}
