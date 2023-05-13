import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp_passenger/data/location_manager.dart';
import 'package:fyp_passenger/data/resource.dart';
import 'package:fyp_passenger/utils/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

  /// Find the device/terminal current position/location and store it in variable for future use.
  late final Position? terminalLocation;
  late final Stream<QuerySnapshot> _driverStream;

  void _getAll() async {
    /// Added driverStream here to be sure it is initialized before th UI is loaded
    _driverStream = firestoreManager.getAllDrivers();
    _routes = firestoreManager.getRoutes(widget.instanceID);
    _terminalName = firestoreManager.getTerminalName(int.parse(instanceID));
    terminalLocation = await locationManager.getCurrentLocation();
  }

  @override
  void initState() {
    _getAll();
    firestoreManager.updateTerminalLocation(instanceID);
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
              'Real Time Passenger Management - ${snapshot.data!} Terminal',
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
                if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
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
                List<RouteInfo> list = snapshot.data!;
                return Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
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

                                /// Added child column in order to display the text underneath
                                /// the main row
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Row(
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
                                          style:
                                              kTerminalStyle.copyWith(fontSize: _fontSize(width)),
                                        )
                                      ],
                                    ),

                                    /// Pass StreamBuilder here, that will actively listen for
                                    /// the driver real time distance from the respective terminal
                                    StreamBuilder(
                                      stream: _driverStream,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting ||
                                            snapshot.data == null) {
                                          return Container();
                                        }
                                        final List<double> distances =
                                            _findNearestDriverLocation(snapshot, list, index);

                                        return distances.isEmpty
                                            ? Text(
                                                'Bus is far away',
                                                style: TextStyle(
                                                  color: Colors.blue[900],
                                                  fontSize: 16,
                                                  fontStyle: FontStyle.italic,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              )
                                            : _convert(distances);
                                      },
                                    ),
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

  List<double> _findNearestDriverLocation(
      AsyncSnapshot<QuerySnapshot<Object?>> snapshot, List<RouteInfo> list, int index) {
    final QuerySnapshot driverQuerySnapshot = snapshot.data!;
    final List<QueryDocumentSnapshot> driverDocs = driverQuerySnapshot.docs;
    List<QueryDocumentSnapshot> specificRouteDrivers = [];
    for (var driverDoc in driverDocs) {
      if (driverDoc['route']['from_terminal'] == list[index].fromTerminal &&
          driverDoc['route']['to_terminal'] == list[index].toTerminal) {
        specificRouteDrivers.add(driverDoc);
      }
    }
    List<double> distances = [];
    for (var driver in specificRouteDrivers) {
      final double driverLatitude = driver['location']['latitude'];
      final double driverLongitude = driver['location']['longitude'];
      distances.add(
        LocationManager.distanceBetween(
          latLng1: LatLng(terminalLocation?.latitude ?? 0.0, terminalLocation?.longitude ?? 0.0),
          latLng2: LatLng(driverLatitude, driverLongitude),
        ),
      );
    }
    distances.sort();
    for (var distance in distances) {
      log('distance: $distance');
    }
    return distances;
  }

  Text _convert(List<double> distances) {
    final double distance = distances.first;
    if (distance >= 1000.0) {
      return Text(
        'Bus is ${(distance / 1000).toStringAsFixed(1)} kilometres away',
        style: TextStyle(
          color: Colors.blue[900],
          fontSize: 16,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      return Text(
        'Bus is ${distance.round()} metres away',
        style: TextStyle(
          color: Colors.blue[900],
          fontSize: 16,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        ),
      );
    }
  }
}
