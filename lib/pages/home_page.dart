import 'package:flutter/material.dart';
import 'package:fyp_passenger/data/resource.dart';
import 'package:fyp_passenger/utils/constants.dart';

import '../models/route_info.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.instanceID});
  final String instanceID;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<RouteInfo>> _routes;
  late final String instanceID = widget.instanceID;
  late final Future<String> _terminalName;

  void _getAll() async {
    _routes = firestoreManager.getRoutes();
    _terminalName = firestoreManager.getTerminalName(int.parse(instanceID));
  }

  @override
  void initState() {
    _getAll();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: _terminalName,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return const Text(
                'Real Time Passenger Management',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 56,
                ),
              );
            }
            return Text(
              'Real Time Passenger Management - ${snapshot.data!} terminal',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            );
          },
        ),
        centerTitle: true,
        toolbarHeight: 100,
        backgroundColor: const Color(0xfff4f3ee),
        foregroundColor: Colors.blue[900],
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Where to?',
                style: TextStyle(
                  fontSize: 64,
                  color: Color(0xff463f3a),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            FutureBuilder(
              future: _routes,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    width: 32.0,
                    height: 32.0,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.black,
                      ),
                    ),
                  );
                }
                if (snapshot.hasData) {
                  List<RouteInfo> list = snapshot.data!;
                  return Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 4,
                      ),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 10,
                                color: const Color(0xffedede9),
                                margin: const EdgeInsets.all(10),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        list[index].fromTerminal,
                                        style: kTerminalStyle.copyWith(
                                          fontSize: _fontSize(width),
                                        ),
                                      ),
                                      CircleAvatar(
                                        foregroundColor: const Color(0xfff4f3ee),
                                        backgroundColor: const Color(0xffbcb8b1),
                                        radius: _fontSize(width),
                                        child: const Icon(Icons.sync_alt),
                                      ),
                                      Text(
                                        list[index].toTerminal,
                                        style: kTerminalStyle.copyWith(fontSize: _fontSize(width)),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            firestoreManager.counter(list[index].reference, int.parse(instanceID));
                          },
                        );
                      },
                      itemCount: list.length,
                    ),
                  );
                }
                return const Center(
                  child: Text('Mhh! Something\'s wrong'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _fontSize(double layoutWidth) {
    if (layoutWidth < 275) {
      return 14.0;
    } else if (layoutWidth < 300) {
      return 18.0;
    } else if (layoutWidth < 420) {
      return 19.0;
    } else {
      return 30.0;
    }
  }
}
