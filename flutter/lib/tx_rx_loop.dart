import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'app_model.dart';
import 'page_base.dart';
import 'serial_port_worker.dart' hide CarControllerPair;

class TxRxLoop extends StatefulWidget {
  const TxRxLoop({super.key});

  @override
  State<TxRxLoop> createState() => _TxRxLoopState();
}

enum ChartType { bar, line }

class _TxRxLoopState extends State<TxRxLoop> {
  StreamSubscription<String>? exceptionStreamSubscription;

  final carControllerColors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.lime,
    Colors.cyan,
    Colors.grey,
    Colors.purple,
    Colors.brown,
    Colors.indigo,
    Colors.pink,
    Colors.teal,
    Colors.deepOrange,
    Colors.blueGrey,
    Colors.deepPurple,
    Colors.lightGreen,
    Colors.lightBlue,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.amberAccent,
  ];

  ChartType chartType = ChartType.bar;

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
        child: Scaffold(
          appBar: AppBar(
            title: const Text('RX'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<AppModel>(builder: (context, model, child) {
              final carControllerPairs = model.carControllerPairs();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(
                  child: SegmentedButton<ChartType>(
                    segments: const [
                      ButtonSegment<ChartType>(
                          value: ChartType.bar, label: Text('Bar chart'), icon: Icon(Icons.bar_chart)),
                      ButtonSegment<ChartType>(
                          value: ChartType.line, label: Text('Line chart'), icon: Icon(Icons.ssid_chart)),
                    ],
                    selected: {chartType},
                    onSelectionChanged: (selected) {
                      if (selected.isNotEmpty) {
                        setState(() {
                          chartType = selected.first;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (chartType == ChartType.bar)
                  Expanded(
                    child: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
                      primaryYAxis: NumericAxis(
                        title: const AxisTitle(text: 'Car/controller RX refresh rate (ms)'),
                        minimum: 0,
                        maximum:
                            model.refreshRatesQueue.isEmpty ? null : model.refreshRatesQueue.reduce(max).toDouble(),
                      ),
                      axes: const [
                        NumericAxis(
                            name: 'yAxisRefreshRate',
                            title: AxisTitle(text: 'RX buffer length (bytes)'),
                            opposedPosition: true,
                            minimum: 0,
                            maximum: 52,
                            interval: 13,
                            majorGridLines: MajorGridLines(width: 0))
                      ],
                      enableSideBySideSeriesPlacement: false,
                      series: [
                        ColumnSeries<MapEntry<int, CarControllerPair>, String>(
                            dataSource: carControllerPairs.toList(),
                            xValueMapper: (data, _) => data.key.toString(),
                            yValueMapper: (data, _) => data.value.rx.refreshRate ?? 0,
                            pointColorMapper: (data, _) => carControllerColors[data.key],
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                            animationDelay: 0,
                            animationDuration: 0,
                            width: 0.3),
                        ColumnSeries<int, String>(
                            dataSource: [model.rxBufferLength],
                            xValueMapper: (_, __) => 'Buffer length',
                            yValueMapper: (data, _) => data,
                            yAxisName: 'yAxisRefreshRate',
                            color: Colors.black,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                            animationDelay: 0,
                            animationDuration: 0,
                            width: 0.3),
                      ],
                    ),
                  ),
                if (chartType == ChartType.line)
                  Expanded(
                      child: SfCartesianChart(
                    primaryXAxis: NumericAxis(
                        minimum: carControllerPairs.isEmpty
                            ? 0
                            : carControllerPairs
                                .map((kv) => kv.value.rx.txRefreshRates.first.timestamp)
                                .reduce(max)
                                .toDouble(),
                        isVisible: false),
                    primaryYAxis:
                        const NumericAxis(title: AxisTitle(text: 'Car/controller RX refresh rate (ms)'), minimum: 0),
                    axes: const [
                      NumericAxis(
                          name: 'yAxisRefreshRate',
                          title: AxisTitle(text: 'RX buffer length (bytes)'),
                          opposedPosition: true,
                          minimum: 0,
                          maximum: 52,
                          interval: 13,
                          majorGridLines: MajorGridLines(width: 0))
                    ],
                    legend: const Legend(isVisible: true),
                    series: [
                      ...carControllerPairs.map(
                        (kv) => LineSeries<CarControllerRxRefreshRate, int>(
                            dataSource: kv.value.rx.txRefreshRates,
                            xValueMapper: (data, _) => data.timestamp,
                            yValueMapper: (data, _) => data.refreshRate,
                            color: carControllerColors[kv.key],
                            animationDelay: 0,
                            animationDuration: 0,
                            name: kv.key.toString()),
                      ),
                      // LineSeries<_ResponseData, int>(
                      //     dataSource: model.rxResponseQueue
                      //         .where((x) => x.rxPreviousControllerDuration != null)
                      //         .map((e) => _ResponseData(x: e.timestamp, y: e.rxPreviousControllerDuration!))
                      //         .toList(),
                      //     xValueMapper: (data, _) => data.x,
                      //     yValueMapper: (data, _) => data.y,
                      //     //yAxisName: 'yAxisRefreshRate',
                      //     color: Colors.red,
                      //     markerSettings: const MarkerSettings(isVisible: true),
                      //     animationDelay: 0,
                      //     animationDuration: 0,
                      //     name: "Time between controllers"),
                      LineSeries<RxResponse, int>(
                          dataSource: model.rxResponseQueue.toList(),
                          xValueMapper: (data, _) => data.timestamp,
                          yValueMapper: (data, _) => data.rxBufferLength,
                          yAxisName: 'yAxisRefreshRate',
                          color: Colors.black,
                          pointColorMapper: (data, _) {
                            final single = data.updatedRxCarControllerPairs.entries.singleOrNull;
                            if (single == null) {
                              return Colors.redAccent;
                            }
                            return carControllerColors[single.key];
                          },
                          markerSettings: const MarkerSettings(isVisible: true),
                          animationDelay: 0,
                          animationDuration: 0,
                          name: "Buffer length")
                    ],
                  ))
              ]);
            }),
          ),
        ),
      )
    ]);
  }
}
