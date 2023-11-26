import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import 'app_model.dart';
import 'oxigen_constants.dart';
import 'serial_port_worker.dart' hide CarControllerPair;
import 'page_base.dart';

class PracticeSession extends StatefulWidget {
  const PracticeSession({super.key});

  @override
  State<PracticeSession> createState() => _PracticeSessionState();
}

class _PracticeSessionState extends State<PracticeSession> {
  StreamSubscription<String>? exceptionStreamSubscription;

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
                appBar: AppBar(title: const Text('Practice session')),
                body: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Align(alignment: Alignment.topCenter, child: Text('There are no connected controllers')),
                ));
          } else {
            return DefaultTabController(
              length: 1 + carControllerPairs.length,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Practice session'),
                  bottom: TabBar(
                    tabs: <Tab>[const Tab(text: 'All controllers')]
                        .followedBy(carControllerPairs.map((x) => Tab(text: 'Id ${x.key.toString()}')))
                        .toList(),
                  ),
                ),
                bottomNavigationBar: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FloatingActionButton(
                        child: const Icon(Icons.play_arrow),
                        onPressed: () => model.oxigenTxRaceStateSet(OxigenTxRaceState.running)),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                        child: const Icon(Icons.pause),
                        onPressed: () => model.oxigenTxRaceStateSet(OxigenTxRaceState.paused)),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                        child: const Icon(Icons.stop),
                        onPressed: () => model.oxigenTxRaceStateSet(OxigenTxRaceState.stopped)),
                  ]),
                ),

                //RaceStateButton(value: model.txRaceState, setValue: model.oxigenTxRaceStateSet),
                body: TabBarView(
                  children: <Widget>[
                    PracticeSessionTabAll(carControllerPairs: carControllerPairs, stopwatch: model.stopwatch)
                  ]
                      .followedBy(carControllerPairs.map((x) => PracticeSessionTabId(
                            id: x.key,
                            carControllerPair: x.value,
                            globalCarControllerPairTx: model.globalCarControllerPairTx(),
                            maximumSpeed: model.maximumSpeed,
                          )))
                      .toList(),
                ),
              ),
            );
          }
        }),
      )
    ]);
  }
}

class PracticeSessionTabAll extends StatelessWidget {
  const PracticeSessionTabAll({super.key, required this.carControllerPairs, required this.stopwatch});
  final Iterable<MapEntry<int, CarControllerPair>> carControllerPairs;
  final Stopwatch stopwatch;

  String timerFormat(int value, int secondsFactor) {
    if (value / secondsFactor < 3600) {
      return '${value / secondsFactor ~/ 60}:${((value / secondsFactor) % 60).toInt().toString().padLeft(2, '0')}';
    } else {
      return '${value / secondsFactor ~/ 3600}:${((value / secondsFactor / 60) % 60).toInt().toString().padLeft(2, '0')}:${((value / secondsFactor) % 60).toInt().toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final fontSize = min(constraints.maxHeight / 23, constraints.maxWidth / carControllerPairs.length / 10);
      final dongleLapRaceTimerMax = carControllerPairs.map((kv) => kv.value.rx.dongleLapRaceTimer).reduce(max);

      return Column(
        children: [
          const SizedBox(height: 16),
          Table(
            children: [
              TableRow(children: [
                Center(
                  child: Text(
                    timerFormat(dongleLapRaceTimerMax, 100),
                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    timerFormat(stopwatch.elapsedMilliseconds, 1000),
                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                  ),
                )
              ]),
              const TableRow(
                  children: [Center(child: Text('Dongle race timer')), Center(child: Text('Computer race timer'))])
            ],
          ),
          Table(
            children: [
              TableRow(
                  children: carControllerPairs
                      .map((kv) => Center(
                              child: Text(
                            kv.key.toString(),
                            style: TextStyle(fontSize: fontSize * 2, fontWeight: FontWeight.bold),
                          )))
                      .toList()),
              TableRow(
                  children: carControllerPairs
                      .map((kv) => Center(
                          child: Text('Laps', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold))))
                      .toList()),
              TableRow(
                  children: carControllerPairs
                      .map((kv) => Center(
                            child: Text(kv.value.rx.calculatedLaps == null ? '' : kv.value.rx.calculatedLaps.toString(),
                                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                          ))
                      .toList()),
              TableRow(
                  children: carControllerPairs
                      .map((kv) => Center(
                          child:
                              Text('Fastest lap', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold))))
                      .toList()),
              TableRow(
                  children: carControllerPairs
                      .map((kv) => Center(
                            child: Text(
                                kv.value.rx.fastestLapTime == null
                                    ? ''
                                    : kv.value.rx.fastestLapTime!.toStringAsFixed(2),
                                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                          ))
                      .toList()),
              TableRow(
                  children: carControllerPairs
                      .map(
                        (kv) => Center(
                          child: Table(
                              columnWidths: const <int, TableColumnWidth>{
                                0: IntrinsicColumnWidth(),
                                1: IntrinsicColumnWidth(),
                                2: IntrinsicColumnWidth(),
                              },
                              children: [
                                TableRow(children: [
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('Lap',
                                          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold))),
                                  SizedBox(width: fontSize),
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('Lap time',
                                          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)))
                                ])
                              ]
                                  .followedBy(kv.value.rx.practiceSessionLaps.map((x) => TableRow(children: [
                                        Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(x.lap.toString(),
                                                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold))),
                                        const SizedBox(width: 16),
                                        Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(x.lapTime.toStringAsFixed(2),
                                                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)))
                                      ])))
                                  .toList()),
                        ),
                      )
                      .toList())
            ],
          ),
        ],
      );
    });
  }
}

class PracticeSessionTabId extends StatelessWidget {
  const PracticeSessionTabId(
      {super.key,
      required this.id,
      required this.carControllerPair,
      required this.globalCarControllerPairTx,
      required this.maximumSpeed});
  final int id;
  final CarControllerPair carControllerPair;
  final TxCarControllerPair globalCarControllerPairTx;
  final int? maximumSpeed;

  @override
  Widget build(BuildContext context) {
    //final spots = carControllerPair.rx.practiceSessionLaps.map((e) => FlSpot(e.lap.toDouble(), e.lapTime)).toList();
    //final showingIndicators = List.generate(spots.length, (index) => index);
    //final LineChartBarData lineChartBarData = LineChartBarData(spots: spots, showingIndicators: showingIndicators);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: NumericAxis(
                title: AxisTitle(text: 'Lap'),
                interval: 1,
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis:
                  NumericAxis(minimum: carControllerPair.rx.fastestLapTime ?? 0, isVisible: false, plotBands: [
                if (carControllerPair.rx.fastestLapTime != null)
                  PlotBand(
                      isVisible: true,
                      start: carControllerPair.rx.fastestLapTime!,
                      end: carControllerPair.rx.fastestLapTime!,
                      borderColor: Colors.green,
                      borderWidth: 4)
              ]),
              series: [
                LineSeries<PracticeSessionLap, int>(
                  dataSource: carControllerPair.rx.practiceSessionLaps.toList(),
                  xValueMapper: (data, _) => data.lap,
                  yValueMapper: (data, _) => data.lapTime,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  markerSettings: const MarkerSettings(isVisible: true),
                  animationDelay: 0,
                  animationDuration: 0,
                ),
              ],
            ),
          ),
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
                        startValue: rangeMinimumSpeed(),
                        endValue: rangeMaximumSpeed(),
                        color: Colors.green,
                      )
                    ],
                  ),
                  RadialAxis(
                    radiusFactor: 0.7,
                    maximum: 127,
                    pointers: [
                      RangePointer(value: carControllerPair.rx.triggerMeanValue.toDouble(), color: Colors.indigo)
                    ],
                    annotations: [
                      GaugeAnnotation(
                        angle: 90,
                        widget: Text(
                          carControllerPair.rx.triggerMeanValue.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 48),
                        ),
                      ),
                      GaugeAnnotation(
                          angle: 90,
                          positionFactor: 0.4,
                          widget: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (carControllerPair.rx.carOnTrack == OxigenRxCarOnTrack.carIsNotOnTheTrack)
                                const Icon(Icons.car_crash, color: Colors.red),
                              if (carControllerPair.rx.carPitLane == OxigenRxCarPitLane.carIsInThePitLane)
                                const Icon(Icons.car_repair),
                              if (carControllerPair.rx.arrowUpButton == OxigenRxArrowUpButton.buttonPressed)
                                const Icon(Icons.arrow_upward),
                              if (carControllerPair.rx.arrowDownButton == OxigenRxArrowDownButton.buttonPressed)
                                const Icon(Icons.arrow_downward),
                              if (carControllerPair.rx.trackCall == OxigenRxTrackCall.yes) const Icon(Icons.flag),
                              if (carControllerPair.rx.controllerBatteryLevel == OxigenRxControllerBatteryLevel.low)
                                const Icon(Icons.battery_alert, color: Colors.red),
                            ],
                          ))
                    ],
                  )
                ],
              ),
              Expanded(
                child: SfCartesianChart(
                  primaryXAxis: NumericAxis(isVisible: false),
                  primaryYAxis: NumericAxis(maximum: 127, minimum: 0),
                  series: [
                    AreaSeries(
                      dataSource: carControllerPair.rx.triggerMeanValues,
                      xValueMapper: (data, _) => data.timestamp,
                      yValueMapper: (data, _) => data.triggerMeanValue,
                      animationDelay: 0,
                      animationDuration: 0,
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double rangeMaximumSpeed() {
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

  double rangeMinimumSpeed() {
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
