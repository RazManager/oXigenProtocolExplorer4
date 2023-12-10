import 'dart:async';
import 'dart:collection';
import 'package:collection/collection.dart';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'oxigen_constants.dart';
import 'serial_port_worker.dart';

class CarControllerPair {
  TxCarControllerPair tx = TxCarControllerPair();
  RxCarControllerPair rx = RxCarControllerPair();
  ScrollController scrollController = ScrollController();
  int? position;
}

class AppModel extends ChangeNotifier {
  AppModel() {
    Isolate.spawn(SerialPortWorker().startAsync, _receivePort.sendPort);
    _serialPortWorkerDataStreamSubscription = _receivePort.listen((message) => _onSerialPortWorkerData(message));
    platForm();
  }

  late String applicationVersion;
  int menuIndex = 0;

  final _receivePort = ReceivePort();
  SendPort? _sendPort;
  StreamSubscription<dynamic>? _serialPortWorkerDataStreamSubscription;

  SerialPortResponse? _serialPortResponse;
  List<SerialPortListResponse> serialPortList = [];
  Timer? _serialPortOpenedTimer;
  int baudRate = 19200;
  List<int> baudRates = [9600, 19200, 38400, 57600, 115200, 128000];

  OxigenTxPitlaneLapCounting? txPitlaneLapCounting;
  OxigenTxPitlaneLapTrigger? txPitlaneLapTrigger;
  OxigenTxRaceState? txRaceState;
  int? maximumSpeed;
  int rxControllerTimeout = 30;
  int rxBufferLength = 0;
  final exceptionStreamController = StreamController<String>.broadcast();

  double? dongleFirmwareVersion;
  final Map<int, CarControllerPair> _carControllerPairs = List.generate(21, (index) => CarControllerPair()).asMap();
  Queue<int> refreshRatesQueue = Queue<int>();
  Queue<RxResponse> rxResponseQueue = Queue<RxResponse>();
  Stopwatch stopwatch = Stopwatch();

  int dongleLapRaceTimerMax = 0;

  void platForm() async {
    var packageInfo = await PackageInfo.fromPlatform();
    applicationVersion = packageInfo.version;
  }

  void serialPortRefresh() {
    _sendPort!.send(SerialPortListRequest());
  }

  void serialPortSet(String name) {
    _sendPort!.send(SerialPortSetRequest(name: name));
  }

  String? serialPortGet() {
    return _serialPortResponse?.name;
  }

  bool serialPortCanOpen() {
    return _serialPortResponse != null &&
        !_serialPortResponse!.isOpen &&
        txPitlaneLapCounting != null &&
        (txPitlaneLapCounting == OxigenTxPitlaneLapCounting.disabled || txPitlaneLapTrigger != null) &&
        txRaceState != null &&
        maximumSpeed != null;
  }

  bool serialPortIsOpen() {
    return _serialPortResponse != null && _serialPortResponse!.isOpen;
  }

  void serialPortOpen() {
    dongleFirmwareVersion = null;
    if (_serialPortOpenedTimer != null) {
      _serialPortOpenedTimer!.cancel();
    }
    _serialPortOpenedTimer = Timer(const Duration(seconds: 5), () {
      if (serialPortIsOpen() && dongleFirmwareVersion == null) {
        exceptionStreamController.add('No dongle firmware version reported. Is an oXigen dongle serial port selected?');
        notifyListeners();
      }
    });

    _sendPort!.send(SerialPortOpenRequest());
  }

  bool serialPortCanClose() {
    return _serialPortResponse != null && _serialPortResponse!.isOpen;
  }

  void serialPortClose() {
    dongleFirmwareVersion = null;
    _sendPort!.send(SerialPortCloseRequest());
  }

  void baudRateSet(int baudRate) {
    _sendPort!.send(BaudRateSetRequest(baudRate: baudRate));
  }

  void oxigenTxPitlaneLapCountingSet(OxigenTxPitlaneLapCounting value) {
    txPitlaneLapCounting = value;
    _sendPort!.send(txPitlaneLapCounting!);
    notifyListeners();
  }

  void oxigenPitlaneLapTriggerModeSet(OxigenTxPitlaneLapTrigger value) {
    txPitlaneLapTrigger = value;
    _sendPort!.send(txPitlaneLapTrigger!);
    notifyListeners();
  }

  void oxigenTxRaceStateSet(OxigenTxRaceState value) {
    if (txRaceState == OxigenTxRaceState.stopped && value == OxigenTxRaceState.running) {
      stopwatch.reset();
    }
    switch (value) {
      case OxigenTxRaceState.running:
      case OxigenTxRaceState.flaggedLcEnabled:
      case OxigenTxRaceState.flaggedLcDisabled:
        stopwatch.start();
        break;
      case OxigenTxRaceState.paused:
      case OxigenTxRaceState.stopped:
        stopwatch.stop();
        break;
    }

    txRaceState = value;
    _sendPort!.send(txRaceState!);
    notifyListeners();
  }

  void oxigenMaximumSpeedSet(int id, int value) {
    maximumSpeed = value;
    _sendPort!.send(MaximumSpeedRequest(maximumSpeed: value));
    notifyListeners();
  }

  void controllerTimeoutSet(int id, int value) {
    rxControllerTimeout = value;
    notifyListeners();
  }

  void oxigenTxMaximumSpeedSet(int id, int value) {
    _carControllerPairs[id]!.tx.maximumSpeed = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.maximumSpeed, tx: _carControllerPairs[id]!.tx));
    notifyListeners();
  }

  void oxigenTxMinimumSpeedSet(int id, int value) {
    _carControllerPairs[id]!.tx.minimumSpeed = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.minimumSpeed, tx: _carControllerPairs[id]!.tx));
    notifyListeners();
  }

  void oxigenTxPitlaneSpeedSet(int id, int value) {
    _carControllerPairs[id]!.tx.pitlaneSpeed = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.pitlaneSpeed, tx: _carControllerPairs[id]!.tx));
    notifyListeners();
  }

  void oxigenTxMaximumBrakeSet(int id, int value) {
    _carControllerPairs[id]!.tx.maximumBrake = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.maximumBrake, tx: _carControllerPairs[id]!.tx));
    notifyListeners();
  }

  void oxigenTxForceLcUpSet(int id, bool value) {
    _carControllerPairs[id]!.tx.forceLcUp = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.forceLcUp, tx: _carControllerPairs[id]!.tx));
    notifyListeners();
  }

  void oxigenTxForceLcDownSet(int id, bool value) {
    _carControllerPairs[id]!.tx.forceLcDown = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.forceLcDown, tx: _carControllerPairs[id]!.tx));
    notifyListeners();
  }

  void oxigenTxTransmissionPowerSet(int id, OxigenTxTransmissionPower value) {
    _carControllerPairs[id]!.tx.transmissionPower = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.transmissionPower, tx: _carControllerPairs[id]!.tx));
    notifyListeners();
  }

  void _onSerialPortWorkerData(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
    } else if (message is SerialPortResponse) {
      _serialPortResponse = message;
      notifyListeners();
    } else if (message is List<SerialPortListResponse>) {
      serialPortList = message;
      notifyListeners();
    } else if (message is RxResponse) {
      rxBufferLength = message.rxBufferLength;

      for (var kv in message.updatedRxCarControllerPairs.entries) {
        _carControllerPairs[kv.key]!.rx = kv.value;
        if (kv.value.refreshRate != null) {
          refreshRatesQueue.addLast(kv.value.refreshRate!);
          while (refreshRatesQueue.length >= 100) {
            refreshRatesQueue.removeFirst();
          }
        }
      }

      var dongleLapRaceTimers = carControllerPairs().map((kv) => kv.value.rx.dongleLapRaceTimer);
      if (dongleLapRaceTimers.isEmpty) {
        dongleLapRaceTimerMax = 0;
      } else {
        dongleLapRaceTimerMax = dongleLapRaceTimers.reduce(max);
      }

      rxResponseQueue.addLast(message);
      rxResponseQueue.removeWhere((x) => x.timestamp < (DateTime.now().millisecondsSinceEpoch - 10 * 1000));

      notifyListeners();
    } else if (message is DongleFirmwareVersionResponse) {
      dongleFirmwareVersion = message.dongleFirmwareVersion;
      notifyListeners();
    } else if (message is SerialPortError) {
      exceptionStreamController.add(message.message);
      notifyListeners();
    }
  }

  TxCarControllerPair globalCarControllerPairTx() {
    return _carControllerPairs[0]!.tx;
  }

  Iterable<MapEntry<int, CarControllerPair>> carControllerPairs() {
    final now = DateTime.now();
    return _carControllerPairs.entries.where((x) =>
        x.key != 0 &&
        x.value.rx.refreshRate != null &&
        x.value.rx.updatedAt != null &&
        x.value.rx.updatedAt!.isAfter(now.add(Duration(milliseconds: -rxControllerTimeout * 1000))));
  }

  Iterable<MapEntry<int, CarControllerPair>> carControllerPairPositions() {
    var sorted = carControllerPairs().sorted((a, b) {
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

    sorted.forEachIndexed((index, x) {
      x.value.position = index + 1;
    });

    return sorted;
  }

  @override
  void dispose() {
    if (_serialPortWorkerDataStreamSubscription != null) {
      _serialPortWorkerDataStreamSubscription!.cancel();
    }
    if (_sendPort != null) {
      _sendPort!.send(null);
    }
    super.dispose();
  }
}
