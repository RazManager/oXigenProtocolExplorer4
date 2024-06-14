import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'app_model.dart';
import 'car_controller_commands.dart';
import 'car_data.dart';
import 'controller_data.dart';
import 'global_commands.dart';
import 'lap_data.dart';
import 'practice_session.dart';
import 'race_session.dart';
import 'settings.dart';
import 'tx_rx_loop.dart';

final router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const SettingsPage()),
    ),
    GoRoute(
      path: '/tx-rx-loop',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const TxRxLoop()),
    ),
    GoRoute(
      path: '/global-commands',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const GlobalCommandsPage()),
    ),
    GoRoute(
      path: '/car-controller-commands',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const CarControllerCommands()),
    ),
    GoRoute(
      path: '/controller-data',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const ControllerDataPage()),
    ),
    GoRoute(
      path: '/car-data',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const CarDataPage()),
    ),
    GoRoute(
      path: '/lap-data',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const LapDataPage()),
    ),
    GoRoute(
      path: '/practice-session',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const PracticeSession()),
    ),
    GoRoute(
      path: '/race-session',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const RaceSession()),
    ),
  ],
);

class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({super.key});

  void showAbout(BuildContext context, String applicationVersion) {
    showAboutDialog(
        context: context,
        //applicationIcon: const ImageIcon(AssetImage('assets/icons/logo.png')),
        applicationName: "oXigen Protocol Explorer 4",
        children: [
          Row(children: [
            Table(columnWidths: const <int, TableColumnWidth>{
              0: IntrinsicColumnWidth(),
              1: IntrinsicColumnWidth(),
            }, children: [
              TableRow(
                  children: [const TableCell(child: Text('Version:  ')), TableCell(child: Text(applicationVersion))]),
              TableRow(children: [
                const TableCell(child: Text('Operating system:  ')),
                TableCell(
                    child: Text(Platform.isAndroid
                        ? 'Android'
                        : Platform.isFuchsia
                            ? 'isFuchsia'
                            : Platform.isIOS
                                ? 'iOS'
                                : Platform.isLinux
                                    ? 'Linux'
                                    : Platform.isMacOS
                                        ? 'MacOS'
                                        : Platform.isWindows
                                            ? 'Windows'
                                            : '?'))
              ]),
              TableRow(children: [
                const TableCell(child: Text('Operating system version:  ')),
                TableCell(child: Text(Platform.operatingSystemVersion))
              ]),
              TableRow(children: [
                const TableCell(child: Text('Dart runtime:  ')),
                TableCell(child: Text(Platform.version))
              ]),
            ])
          ])
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.read<AppModel>();
    return LayoutBuilder(
      builder: (context, constraint) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraint.maxHeight),
            child: IntrinsicHeight(
              child: NavigationRail(
                selectedIndex: model.menuIndex,
                useIndicator: true,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (index) {
                  model.menuIndex = index;
                  switch (index) {
                    case 0:
                      context.go('/');
                      break;

                    case 1:
                      context.go('/tx-rx-loop');
                      break;

                    case 2:
                      context.go('/global-commands');
                      break;

                    case 3:
                      context.go('/car-controller-commands');
                      break;

                    case 4:
                      context.go('/controller-data');
                      break;

                    case 5:
                      context.go('/car-data');
                      break;

                    case 6:
                      context.go('/lap-data');
                      break;

                    case 7:
                      context.go('/practice-session');
                      break;

                    case 8:
                      context.go('/race-session');
                      break;

                    case 9:
                      showAbout(context, model.applicationVersion);
                      break;
                    default:
                  }
                },
                leading: const Text(
                  '4',
                  style: TextStyle(fontFamily: 'BungeeInline', fontSize: 40),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.send),
                    label: Text('RX'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.tune),
                    label: Text('Global commands'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.tune),
                    label: Text('Car/controller commands'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.speed),
                    label: Text('Controller data'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.drive_eta),
                    label: Text('Car data'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.timer),
                    label: Text('Lap data'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.sports_motorsports),
                    label: Text('Practice session'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.sports_motorsports),
                    label: Text('Race session'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.info),
                    label: Text('About'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

abstract class PageBase extends StatefulWidget {
  const PageBase({super.key, required this.title, required this.body});

  final String title;
  final Widget body;
}

abstract class PageBaseState<TPageBase extends PageBase> extends State<TPageBase> {
  final scrollController = ScrollController();
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
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(padding: const EdgeInsets.all(16.0), child: widget.body),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
