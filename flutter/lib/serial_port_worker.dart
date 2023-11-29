import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'oxigen_constants.dart';

class TxCarControllerPair {
  int? maximumSpeed;
  int? minimumSpeed;
  int? pitlaneSpeed;
  int? maximumBrake;
  bool? forceLcUp;
  bool? forceLcDown;
  OxigenTxTransmissionPower? transmissionPower;
}

class RxCarControllerPair {
  OxigenRxCarReset carReset = OxigenRxCarReset.carPowerSupplyHasntChanged;
  int carResetCount = 0;
  OxigenRxControllerCarLink controllerCarLink = OxigenRxControllerCarLink.controllerLinkWithItsPairedCarHasntChanged;
  int controllerCarLinkCount = 0;
  late OxigenRxControllerBatteryLevel controllerBatteryLevel;
  late OxigenRxTrackCall trackCall;
  late OxigenRxArrowUpButton arrowUpButton;
  late OxigenRxArrowDownButton arrowDownButton;
  late OxigenRxRoundButton roundButton;
  late OxigenRxCarOnTrack carOnTrack;
  late OxigenRxCarPitLane carPitLane;
  late int triggerMeanValue;
  late int dongleRaceTimer;
  late int dongleLapRaceTimer;
  late int dongleLapTime;
  late double dongleLapTimeSeconds;
  late int dongleLapTimeDelay;
  int dongleLaps = 0;
  int? previousLapRaceTimer;
  double? calculatedLapTimeSeconds;
  int? calculatedLaps;
  double? controllerFirmwareVersion;
  double? carFirmwareVersion;
  DateTime? updatedAt;
  int? refreshRate;
  List<CarControllerRxRefreshRate> txRefreshRates = [];
  double? fastestLapTime;
  List<TriggerMeanValue> triggerMeanValues = [];
  Queue<PracticeSessionLap> practiceSessionLaps = Queue<PracticeSessionLap>();
}

class TriggerMeanValue {
  TriggerMeanValue({required this.timestamp, required this.triggerMeanValue});

  final int timestamp;
  final int triggerMeanValue;
}

class PracticeSessionLap {
  PracticeSessionLap({required this.lap, required this.lapTime});

  final int lap;
  final double lapTime;
}

class TxCommand {
  TxCommand({required this.id, required this.command, required this.tx});

  final int id;
  final OxigenTxCommand command;
  final TxCarControllerPair tx;
}

class CarControllerRxRefreshRate {
  CarControllerRxRefreshRate({required this.timestamp, required this.refreshRate});

  final int timestamp;
  final int refreshRate;
}

class MaximumSpeedRequest {
  MaximumSpeedRequest({required this.maximumSpeed});

  final int maximumSpeed;
}

class SerialPortListRequest {}

class SerialPortListResponse {
  SerialPortListResponse({required this.name, required this.description});
  final String name;
  final String description;
}

class SerialPortSetRequest {
  SerialPortSetRequest({required this.name});
  final String name;
}

class SerialPortOpenRequest {}

class SerialPortCloseRequest {}

class SerialPortResponse {
  SerialPortResponse(SerialPort? serialPort, String? serialPortName) {
    name = serialPortName;
    if (serialPort == null) {
      isOpen = false;
    } else {
      isOpen = serialPort.isOpen;
    }
  }

  String? name;
  bool isOpen = false;
}

class DongleFirmwareVersionResponse {
  DongleFirmwareVersionResponse({required this.dongleFirmwareVersion});

  final double dongleFirmwareVersion;
}

class RxResponse {
  RxResponse({required this.timestamp, required this.rxBufferLength});

  final int timestamp;
  final int rxBufferLength;
  Map<int, RxCarControllerPair> updatedRxCarControllerPairs = {};
}

class CarControllerPair {
  TxCarControllerPair tx = TxCarControllerPair();
  RxCarControllerPair rx = RxCarControllerPair();
}

class SerialPortWorker {
  late SendPort _callbackPort;
  String? _serialPortName;
  SerialPort? _serialPort;
  SerialPortReader? _serialPortReader;
  StreamSubscription<Uint8List>? _serialPortStreamSubscription;

  OxigenTxPitlaneLapCounting? _txPitlaneLapCounting;
  OxigenTxPitlaneLapTrigger? _txPitlaneLapTrigger;
  OxigenTxRaceState? _txRaceState;
  int? _maximumSpeed;
  Uint8List? _unusedBuffer;

  final Map<int, CarControllerPair> _carControllerPairs = List.generate(21, (index) => CarControllerPair()).asMap();

  Future<void> startAsync(SendPort callbackPort) async {
    _callbackPort = callbackPort;
    final commandPort = ReceivePort();
    callbackPort.send(commandPort.sendPort);
    _serialPortList();

    await for (final message in commandPort) {
      if (message is SerialPortListRequest) {
        _serialPortList();
      } else if (message is SerialPortSetRequest) {
        _serialPortSet(message.name);
      } else if (message is SerialPortOpenRequest) {
        _serialPortOpen();
      } else if (message is SerialPortCloseRequest) {
        _serialPortClose();
      } else if (message is OxigenTxPitlaneLapCounting) {
        _txPitlaneLapCounting = message;
        _serialPortTx(null);
      } else if (message is OxigenTxPitlaneLapTrigger) {
        _txPitlaneLapTrigger = message;
        _serialPortTx(null);
      } else if (message is OxigenTxRaceState) {
        bool resetRaceTimer = false;
        if (_txRaceState == OxigenTxRaceState.stopped && message == OxigenTxRaceState.running) {
          resetRaceTimer = true;
          for (final x in _carControllerPairs.entries) {
            x.value.rx.previousLapRaceTimer = null;
            x.value.rx.calculatedLapTimeSeconds = null;
            x.value.rx.calculatedLaps = null;
            x.value.rx.fastestLapTime = null;
            x.value.rx.practiceSessionLaps = Queue<PracticeSessionLap>();
          }
        }
        _txRaceState = message;
        if (resetRaceTimer) {
          _serialPortTx(null);
        }
        _serialPortTx(null);
      } else if (message is MaximumSpeedRequest) {
        _maximumSpeed = message.maximumSpeed;
        _serialPortTx(null);
      } else if (message is TxCommand) {
        _carControllerPairs[message.id]!.tx = message.tx;
        _serialPortTx(message);
      } else if (message == null) {
        break;
      }
    }
  }

  void _serialPortList() {
    try {
      _serialPortClear();
      final availablePortNames = SerialPort.availablePorts;
      final List<SerialPortListResponse> result = [];
      for (final address in availablePortNames) {
        final port = SerialPort(address);
        String vendorIdProductId = '';
        try {
          if (port.vendorId != null) {
            vendorIdProductId += 'Vendor id: 0x${port.vendorId?.toRadixString(16)}';
          }
          if (port.productId != null) {
            if (vendorIdProductId != '') {
              vendorIdProductId += ', ';
            }
            vendorIdProductId += 'Product id: 0x${port.productId?.toRadixString(16)}';
          }
          if (vendorIdProductId != '') {
            vendorIdProductId = ' ($vendorIdProductId)';
          }
        } on SerialPortError {}
        result.add(SerialPortListResponse(name: address, description: '${port.description}$vendorIdProductId'));
        port.dispose();
      }

      _callbackPort.send(result);
      if (availablePortNames.isNotEmpty) {
        for (final address in availablePortNames) {
          final port = SerialPort(address);
          try {
            if (port.vendorId != null && port.vendorId == 0x1FEE && port.productId != null && port.productId == 0x2) {
              _serialPortSet(address);
              port.dispose();
              break;
            }
            port.dispose();
          } on SerialPortError {}
          if (_serialPort == null) {
            _serialPortSet(availablePortNames.first);
          }
        }
      }
    } on SerialPortError catch (e) {
      print('_serialPortRefresh SerialPortError error: ${e.message}');
      _callbackPort.send(e);
    } catch (e) {
      print('_serialPortRefresh error: $e');
      _callbackPort.send(e);
    }
  }

  void _serialPortSet(String name) {
    print('_serialPortSet $name');
    _serialPortClear();
    _serialPortName = name;
    _callbackPort.send(SerialPortResponse(_serialPort, _serialPortName));
  }

  void _serialPortClear() {
    if (_serialPortStreamSubscription != null) {
      _serialPortStreamSubscription!.cancel();
      _serialPortStreamSubscription = null;
    }
    if (_serialPortReader != null) {
      _serialPortReader!.close();
      _serialPortReader = null;
    }
    if (_serialPort != null) {
      if (_serialPort!.isOpen) {
        if (!_serialPort!.close() && SerialPort.lastError != null) {
          _callbackPort.send(SerialPort.lastError);
        }
        //_serialPort!.dispose();
        _serialPort = null;
      }
    }
  }

  void _serialPortReset() {
    try {
      _serialPortClear();
      _serialPortOpen();
    } on SerialPortError catch (e) {
      print('_serialPortReset SerialPortError error: ${e.message}');
      _callbackPort.send(e);
    } catch (e) {
      print('_serialPortReset error: $e');
      _callbackPort.send(e);
    }
  }

  bool _serialPortIsOpen() {
    try {
      return _serialPort != null && _serialPort!.isOpen;
    } on SerialPortError catch (e) {
      print('_serialPortIsOpen SerialPortError error: ${e.message}');
      _callbackPort.send(e);
      return false;
    } catch (e) {
      print('_serialPortIsOpen error: $e');
      _callbackPort.send(e);
      return false;
    }
  }

  void _serialPortOpen() {
    try {
      _serialPort = SerialPort(_serialPortName!);
      if (!_serialPort!.openReadWrite() && SerialPort.lastError != null) {
        _callbackPort.send(SerialPort.lastError);
        return;
      }

      final serialPortConfig = SerialPortConfig();
      serialPortConfig.baudRate = 9600;
      serialPortConfig.bits = 8;
      serialPortConfig.parity = SerialPortParity.none;
      serialPortConfig.stopBits = 1;
      serialPortConfig.setFlowControl(SerialPortFlowControl.dtrDsr);
      serialPortConfig.dtr = SerialPortDtr.on;
      serialPortConfig.dsr = SerialPortDsr.ignore;
      serialPortConfig.rts = SerialPortRts.off;
      serialPortConfig.xonXoff = SerialPortXonXoff.disabled;
      _serialPort!.config = serialPortConfig;
      serialPortConfig.dispose();

      _callbackPort.send(SerialPortResponse(_serialPort, _serialPortName));
      _serialPortRx();
      _serialPortDongleCommandDongleFirmwareVersion();
    } on SerialPortError catch (e) {
      print('_serialPortOpen SerialPortError error: ${e.message}');
      _callbackPort.send(e);
    } catch (e) {
      print('_serialPortOpen error: $e');
      _callbackPort.send(e);
    }
  }

  void _serialPortClose() {
    try {
      _serialPortClear();
      _callbackPort.send(SerialPortResponse(_serialPort, _serialPortName));
    } on SerialPortError catch (e) {
      print('_serialPortClose SerialPortError error: ${e.message}');
      _callbackPort.send(e);
    } catch (e) {
      print('_serialPortClose error: $e');
      _callbackPort.send(e);
    }
  }

  void _serialPortDongleCommandDongleFirmwareVersion() {
    try {
      final bytes = Uint8List.fromList([6, 6, 6, 6, 0, 0, 0]);
      _serialPort!.write(bytes);
    } on SerialPortError catch (e) {
      print('_serialPortDongleCommandDongleFirmwareVersion SerialPortError error: ${e.message}');
      _callbackPort.send(e);
    } catch (e) {
      print('_serialPortDongleCommandDongleFirmwareVersion error: $e');
      _callbackPort.send(e);
    }
  }

  void _serialPortRxInit() {
    try {
      final bytes = Uint8List.fromList([15, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
      _serialPort!.write(bytes);
      _serialPortTx(null);
    } on SerialPortError catch (e) {
      print('_serialPortRxInit SerialPortError error: ${e.message}');
      _callbackPort.send(e);
    } catch (e) {
      print('_serialPortRxInit error: $e');
      _callbackPort.send(e);
    }
  }

  void _serialPortTx(TxCommand? txCommand) {
    if (!_serialPortIsOpen()) {
      return;
    }

    try {
      int byte0;
      switch (_txRaceState) {
        case null:
          return;
        case OxigenTxRaceState.running:
          byte0 = 0x3;
          break;
        case OxigenTxRaceState.paused:
          byte0 = 0x4;
          break;
        case OxigenTxRaceState.stopped:
          byte0 = 0x1;
          break;
        case OxigenTxRaceState.flaggedLcEnabled:
          byte0 = 0x5;
          break;
        case OxigenTxRaceState.flaggedLcDisabled:
          byte0 = 0x15;
          break;
      }

      switch (_txPitlaneLapCounting) {
        case null:
          return;
        case OxigenTxPitlaneLapCounting.enabled:
          break;
        case OxigenTxPitlaneLapCounting.disabled:
          byte0 = byte0 | (pow(2, 5) as int);
          break;
      }

      if (_txPitlaneLapCounting != null && _txPitlaneLapCounting == OxigenTxPitlaneLapCounting.enabled) {
        switch (_txPitlaneLapTrigger) {
          case null:
            return;
          case OxigenTxPitlaneLapTrigger.pitlaneEntry:
            break;
          case OxigenTxPitlaneLapTrigger.pitlaneExit:
            byte0 = byte0 | (pow(2, 6) as int);
            break;
        }
      }

      if (_maximumSpeed == null) {
        return;
      }

      if (!_serialPortIsOpen()) {
        return;
      }

      var byte3 = 0;
      var byte4 = 0;

      if (txCommand != null && txCommand.id == 0) {
        final txCarControllerPair = _carControllerPairs[0]!.tx;

        switch (txCommand.command) {
          case OxigenTxCommand.maximumSpeed:
            byte3 = 2;
            byte4 = txCarControllerPair.maximumSpeed ?? 0;
            break;
          case OxigenTxCommand.minimumSpeed:
          case OxigenTxCommand.forceLcUp:
          case OxigenTxCommand.forceLcDown:
            byte3 = 3;
            byte4 = (txCarControllerPair.minimumSpeed ?? 0) |
                (txCarControllerPair.forceLcDown == null
                    ? 0
                    : txCarControllerPair.forceLcDown!
                        ? 64
                        : 0) |
                (txCarControllerPair.forceLcUp == null
                    ? 0
                    : txCarControllerPair.forceLcUp!
                        ? 128
                        : 0);
            break;
          case OxigenTxCommand.pitlaneSpeed:
            byte3 = 1;
            byte4 = txCarControllerPair.pitlaneSpeed ?? 0;
            break;
          case OxigenTxCommand.maximumBrake:
            byte3 = 5;
            byte4 = txCarControllerPair.maximumBrake ?? 0;
            break;
          case OxigenTxCommand.transmissionPower:
            byte3 = 4;
            byte4 = txCarControllerPair.transmissionPower?.index ?? 0;
            break;
        }
      }

      var id = 0;
      var byte5 = 0;
      var byte6 = 0;

      if (txCommand != null && txCommand.id != 0) {
        id = txCommand.id;
        final txCarControllerPair = _carControllerPairs[id]!.tx;

        switch (txCommand.command) {
          case OxigenTxCommand.maximumSpeed:
            byte5 = 2;
            byte6 = txCarControllerPair.maximumSpeed ?? 0;
            break;
          case OxigenTxCommand.minimumSpeed:
          case OxigenTxCommand.forceLcUp:
          case OxigenTxCommand.forceLcDown:
            byte5 = 3;
            byte6 = (txCarControllerPair.minimumSpeed ?? 0) |
                (txCarControllerPair.forceLcDown == null
                    ? 0
                    : txCarControllerPair.forceLcDown!
                        ? 64
                        : 0) |
                (txCarControllerPair.forceLcUp == null
                    ? 0
                    : txCarControllerPair.forceLcUp!
                        ? 128
                        : 0);
            break;
          case OxigenTxCommand.pitlaneSpeed:
            byte5 = 1;
            byte6 = txCarControllerPair.pitlaneSpeed ?? 0;
            break;
          case OxigenTxCommand.maximumBrake:
            byte5 = 5;
            byte6 = txCarControllerPair.maximumBrake ?? 0;
            break;
          case OxigenTxCommand.transmissionPower:
            byte5 = 4;
            byte6 = txCarControllerPair.transmissionPower?.index ?? 0;
            break;
        }

        if (id > 0) {
          byte5 = byte5 | 0x80;
        }
      }

      final bytes = Uint8List.fromList([byte0, _maximumSpeed!, id, byte3, byte4, byte5, byte6, 0, 0, 0, 0]);
      //print(bytes);
      _serialPort!.write(bytes, timeout: 0);
    } on SerialPortError catch (e) {
      print('_serialPortWriteLoop SerialPortError error: ${e.message}');
      _callbackPort.send(e);
      _serialPortReset();
    } catch (e) {
      print('_serialPortWriteLoop error: $e');
      _callbackPort.send(e);
    }
  }

  void _serialPortRx() {
    _serialPortReader = SerialPortReader(_serialPort!);
    _serialPortStreamSubscription = _serialPortReader!.stream.listen((buffer) async {
      final now = DateTime.now();
      try {
        //print(buffer.length);
        if (buffer.length == 5) {
          _unusedBuffer = null;
          _callbackPort.send(DongleFirmwareVersionResponse(dongleFirmwareVersion: buffer[0] + buffer[1] / 100));
          _callbackPort.send(RxResponse(timestamp: now.millisecondsSinceEpoch, rxBufferLength: buffer.length));
          _serialPortRxInit();
        } else if (buffer.length % 13 == 0) {
          _unusedBuffer = null;
          _callbackPort.send(_processBuffer(buffer, buffer.length, now));
        } else {
          print('Got ${buffer.length} characters from stream');
          if (_unusedBuffer == null) {
            _unusedBuffer = buffer;
          } else {
            final bytesBuilder = BytesBuilder();
            bytesBuilder.add(_unusedBuffer!);
            bytesBuilder.add(buffer);
            _unusedBuffer = bytesBuilder.toBytes();
          }
          if (_unusedBuffer!.length % 13 == 0) {
            print('Combining ${_unusedBuffer!.length} characters from stream');
            _callbackPort.send(_processBuffer(_unusedBuffer!, buffer.length, now));
          } else {
            _callbackPort.send(RxResponse(timestamp: now.millisecondsSinceEpoch, rxBufferLength: buffer.length));
          }
        }
      } on SerialPortError catch (e) {
        print('_serialPortReadStream SerialPortError error: ${e.message}');
        _callbackPort.send(e);
        _serialPortReset();
      } catch (e) {
        print('_serialPortReadStream error: $e');
        _callbackPort.send(e);
      }
    });
  }

  RxResponse _processBuffer(Uint8List buffer, int rxBufferLength, DateTime now) {
    final result = RxResponse(timestamp: now.millisecondsSinceEpoch, rxBufferLength: rxBufferLength);
    var offset = 0;
    do {
      final id = buffer[1 + offset];

      _processCarControllerBuffer(
          rxCarControllerPair: _carControllerPairs[id]!.rx,
          buffer: Uint8List.view(buffer.buffer, offset, 13),
          now: now);

      if (_carControllerPairs[id]!.rx.refreshRate != null) {
        _carControllerPairs[id]!.rx.txRefreshRates.add(CarControllerRxRefreshRate(
            timestamp: now.millisecondsSinceEpoch, refreshRate: _carControllerPairs[id]!.rx.refreshRate!));
        _carControllerPairs[id]!
            .rx
            .txRefreshRates
            .removeWhere((x) => x.timestamp < (now.millisecondsSinceEpoch - 10 * 1000));
      }

      result.updatedRxCarControllerPairs[id] = _carControllerPairs[id]!.rx;

      offset = offset + 13;
    } while (offset < buffer.length - 1);
    //print(DateTime.now().microsecondsSinceEpoch - now.microsecondsSinceEpoch);

    return result;
  }

  void _processCarControllerBuffer(
      {required RxCarControllerPair rxCarControllerPair, required Uint8List buffer, required DateTime now}) {
    final oldCarReset = rxCarControllerPair.carReset;
    final oldControllerCarLink = rxCarControllerPair.controllerCarLink;
    final oldDongleLaps = rxCarControllerPair.dongleLaps;

    //print(buffer);

    if (buffer[0] & (pow(2, 0) as int) == 0) {
      rxCarControllerPair.carReset = OxigenRxCarReset.carPowerSupplyHasntChanged;
    } else {
      rxCarControllerPair.carReset = OxigenRxCarReset.carHasJustBeenPoweredUpOrReset;
    }
    if (rxCarControllerPair.carReset == OxigenRxCarReset.carHasJustBeenPoweredUpOrReset &&
        oldCarReset != rxCarControllerPair.carReset) {
      rxCarControllerPair.carResetCount++;
    }

    if (buffer[0] & (pow(2, 1) as int) == 0) {
      rxCarControllerPair.controllerCarLink = OxigenRxControllerCarLink.controllerLinkWithItsPairedCarHasntChanged;
    } else {
      rxCarControllerPair.controllerCarLink = OxigenRxControllerCarLink.controllerHasJustGotTheLinkWithItsPairedCar;
    }
    if (rxCarControllerPair.controllerCarLink ==
            OxigenRxControllerCarLink.controllerHasJustGotTheLinkWithItsPairedCar &&
        oldControllerCarLink != rxCarControllerPair.controllerCarLink) {
      rxCarControllerPair.controllerCarLinkCount++;
    }

    if (buffer[0] & (pow(2, 4) as int) == 0) {
      rxCarControllerPair.carPitLane = OxigenRxCarPitLane.carIsNotInThePitLane;
    } else {
      rxCarControllerPair.carPitLane = OxigenRxCarPitLane.carIsInThePitLane;
    }

    if (buffer[7] & (pow(2, 7) as int) == 0) {
      rxCarControllerPair.carOnTrack = OxigenRxCarOnTrack.carIsNotOnTheTrack;
    } else {
      rxCarControllerPair.carOnTrack = OxigenRxCarOnTrack.carIsOnTheTrack;
    }

    if (buffer[9] & (pow(2, 2) as int) == 0) {
      rxCarControllerPair.controllerBatteryLevel = OxigenRxControllerBatteryLevel.ok;
    } else {
      rxCarControllerPair.controllerBatteryLevel = OxigenRxControllerBatteryLevel.low;
    }

    if (buffer[9] & (pow(2, 3) as int) == 0) {
      rxCarControllerPair.trackCall = OxigenRxTrackCall.no;
    } else {
      rxCarControllerPair.trackCall = OxigenRxTrackCall.yes;
    }

    if (buffer[9] & (pow(2, 5) as int) == 0) {
      rxCarControllerPair.arrowUpButton = OxigenRxArrowUpButton.buttonNotPressed;
    } else {
      rxCarControllerPair.arrowUpButton = OxigenRxArrowUpButton.buttonPressed;
    }

    if (buffer[9] & (pow(2, 6) as int) == 0) {
      rxCarControllerPair.arrowDownButton = OxigenRxArrowDownButton.buttonNotPressed;
    } else {
      rxCarControllerPair.arrowDownButton = OxigenRxArrowDownButton.buttonPressed;
    }

    if (buffer[9] & (pow(2, 7) as int) == 0) {
      rxCarControllerPair.roundButton = OxigenRxRoundButton.buttonNotPressed;
    } else {
      rxCarControllerPair.roundButton = OxigenRxRoundButton.buttonPressed;
    }

    rxCarControllerPair.triggerMeanValue = buffer[7] & 0x7F;
    rxCarControllerPair.dongleLapTime = buffer[2] * 256 + buffer[3];
    rxCarControllerPair.dongleLapTimeDelay = buffer[4];
    rxCarControllerPair.dongleLaps = buffer[6] * 256 + buffer[5];

    OxigenRxDeviceSoftwareReleaseOwner deviceSoftwareReleaseOwner;
    if (buffer[8] & (pow(2, 7) as int) == 0) {
      deviceSoftwareReleaseOwner = OxigenRxDeviceSoftwareReleaseOwner.controllerSoftwareRelease;
    } else {
      deviceSoftwareReleaseOwner = OxigenRxDeviceSoftwareReleaseOwner.carSoftwareRelease;
    }

    final softwareRelease = 4 + (buffer[8] & 96) / 32 + (buffer[8] & 15) / 100;

    switch (deviceSoftwareReleaseOwner) {
      case OxigenRxDeviceSoftwareReleaseOwner.controllerSoftwareRelease:
        rxCarControllerPair.controllerFirmwareVersion = softwareRelease;
        break;
      case OxigenRxDeviceSoftwareReleaseOwner.carSoftwareRelease:
        if (rxCarControllerPair.carOnTrack == OxigenRxCarOnTrack.carIsOnTheTrack) {
          rxCarControllerPair.carFirmwareVersion = softwareRelease;
        }
        break;
    }

    rxCarControllerPair.dongleRaceTimer = buffer[10] * 65536 + buffer[11] * 256 + buffer[12];
    //print(
    //    'oldDongleLaps=$oldDongleLaps dongleLaps=${rxCarControllerPair.dongleLaps} dongleRaceTimer=${rxCarControllerPair.dongleRaceTimer} previousLapRaceTimer=${rxCarControllerPair.previousLapRaceTimer}');

    rxCarControllerPair.dongleLapRaceTimer =
        rxCarControllerPair.dongleRaceTimer - rxCarControllerPair.dongleLapTimeDelay;

    rxCarControllerPair.dongleLapTimeSeconds = rxCarControllerPair.dongleLapTime / 99.25;

    if (oldDongleLaps != rxCarControllerPair.dongleLaps) {
      // New lap, or the car crossed the start/finish line for the first time.
      if (rxCarControllerPair.dongleLaps == 0 || rxCarControllerPair.calculatedLaps == null) {
        rxCarControllerPair.calculatedLaps = 0;
      } else {
        rxCarControllerPair.calculatedLaps = rxCarControllerPair.calculatedLaps! + 1;
        if (rxCarControllerPair.previousLapRaceTimer != null) {
          rxCarControllerPair.calculatedLapTimeSeconds =
              (rxCarControllerPair.dongleLapRaceTimer - rxCarControllerPair.previousLapRaceTimer!) / 100.0;

          if (rxCarControllerPair.fastestLapTime == null ||
              rxCarControllerPair.fastestLapTime! > rxCarControllerPair.calculatedLapTimeSeconds!) {
            rxCarControllerPair.fastestLapTime = rxCarControllerPair.calculatedLapTimeSeconds!;
          }

          rxCarControllerPair.practiceSessionLaps.addFirst(PracticeSessionLap(
              lap: rxCarControllerPair.calculatedLaps!, lapTime: rxCarControllerPair.calculatedLapTimeSeconds!));
          if (rxCarControllerPair.practiceSessionLaps.length >= 6) {
            rxCarControllerPair.practiceSessionLaps.removeLast();
          }
        }
      }
      rxCarControllerPair.previousLapRaceTimer = rxCarControllerPair.dongleLapRaceTimer;
    }

    if (rxCarControllerPair.updatedAt != null) {
      rxCarControllerPair.refreshRate =
          now.millisecondsSinceEpoch - rxCarControllerPair.updatedAt!.millisecondsSinceEpoch;
    }
    rxCarControllerPair.updatedAt = now;

    rxCarControllerPair.triggerMeanValues.add(TriggerMeanValue(
        timestamp: now.millisecondsSinceEpoch, triggerMeanValue: rxCarControllerPair.triggerMeanValue));
    rxCarControllerPair.triggerMeanValues.removeWhere((x) => x.timestamp < (now.millisecondsSinceEpoch - 10 * 1000));
  }
}
