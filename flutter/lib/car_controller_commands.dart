import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'command_slider.dart';
import 'oxigen_constants.dart';
import 'page_base.dart';

// Car/controller commands view

class CarControllerCommands extends StatefulWidget {
  const CarControllerCommands({super.key});

  @override
  State<CarControllerCommands> createState() => _CarControllerCommandsState();
}

class _CarControllerCommandsState extends State<CarControllerCommands> {
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
    return Row(
      children: [
        const AppNavigationRail(),
        Expanded(
          child: Consumer<AppModel>(builder: (context, model, child) {
            final carControllerPairs = model.carControllerPairs();
            if (carControllerPairs.isEmpty) {
              return Scaffold(
                  appBar: AppBar(title: const Text('Car/controller commands')),
                  body: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Align(alignment: Alignment.topCenter, child: Text('There are no connected controllers')),
                  ));
            } else {
              return DefaultTabController(
                length: carControllerPairs.length,
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text('Car/controller commands'),
                    bottom: TabBar(
                      tabs: carControllerPairs.map((x) => Tab(text: 'Id ${x.key.toString()}')).toList(),
                    ),
                  ),
                  body: TabBarView(
                      children: carControllerPairs
                          .map((x) => Scrollbar(
                                controller: x.value.scrollController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: x.value.scrollController,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Maximum speed',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        CommandSlider(
                                            max: 255,
                                            id: x.key,
                                            value: x.value.tx.maximumSpeed,
                                            setValue: model.oxigenTxMaximumSpeedSet),
                                        const Text(
                                          'Minimum speed',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        CommandSlider(
                                            max: 63,
                                            id: x.key,
                                            value: x.value.tx.minimumSpeed,
                                            setValue: model.oxigenTxMinimumSpeedSet),
                                        const Text(
                                          'Pitlane speed',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        CommandSlider(
                                            max: 255,
                                            id: x.key,
                                            value: x.value.tx.pitlaneSpeed,
                                            setValue: model.oxigenTxPitlaneSpeedSet),
                                        const Text(
                                          'Maximum brake',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        CommandSlider(
                                            max: 255,
                                            id: x.key,
                                            value: x.value.tx.maximumBrake,
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
                                                thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                                                    (Set<MaterialState> states) {
                                                  if (states.contains(MaterialState.selected)) {
                                                    return const Icon(Icons.arrow_upward);
                                                  }
                                                  if (x.value.tx.forceLcUp != null) {
                                                    return const Icon(Icons.close);
                                                  }
                                                  return const Icon(Icons.question_mark);
                                                }),
                                                value: x.value.tx.forceLcUp ?? false,
                                                onChanged: (value) => model.oxigenTxForceLcUpSet(x.key, value),
                                              ),
                                            ]),
                                            TableRow(children: [
                                              const Text(
                                                'Force lane change down  ',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Switch(
                                                thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                                                    (Set<MaterialState> states) {
                                                  if (states.contains(MaterialState.selected)) {
                                                    return const Icon(Icons.arrow_downward);
                                                  }
                                                  if (x.value.tx.forceLcDown != null) {
                                                    return const Icon(Icons.close);
                                                  }
                                                  return const Icon(Icons.question_mark);
                                                }),
                                                value: x.value.tx.forceLcDown ?? false,
                                                onChanged: (value) => model.oxigenTxForceLcDownSet(x.key, value),
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
                                            ButtonSegment<OxigenTxTransmissionPower>(
                                                value: OxigenTxTransmissionPower.dBm18, label: Text('-18 dBm')),
                                            ButtonSegment<OxigenTxTransmissionPower>(
                                                value: OxigenTxTransmissionPower.dBm12, label: Text('-12 dBm')),
                                            ButtonSegment<OxigenTxTransmissionPower>(
                                                value: OxigenTxTransmissionPower.dBm6, label: Text('-6 dBm')),
                                            ButtonSegment<OxigenTxTransmissionPower>(
                                                value: OxigenTxTransmissionPower.dBm0, label: Text('0 dBm')),
                                          ],
                                          emptySelectionAllowed: true,
                                          selected: x.value.tx.transmissionPower == null
                                              ? {}
                                              : {x.value.tx.transmissionPower!},
                                          onSelectionChanged: (selected) {
                                            if (selected.isNotEmpty) {
                                              model.oxigenTxTransmissionPowerSet(x.key, selected.first);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ))
                          .toList()),
                ),
              );
            }
          }),
        )
      ],
    );
  }
}
