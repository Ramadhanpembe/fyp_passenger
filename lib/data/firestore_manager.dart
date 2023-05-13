import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_passenger/data/resource.dart';
import 'package:fyp_passenger/models/request.dart';
import 'package:fyp_passenger/models/route_info.dart';
import 'package:fyp_passenger/models/terminal.dart';
import 'package:fyp_passenger/models/terminal_location.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreManager {
  late final FirebaseFirestore _db;

  FirestoreManager() {
    _init();
  }

  void _init() {
    _db = FirebaseFirestore.instance;
  }

  void counter(String routeRef, int terminalID) async {
    final docRef = _db.collection('routes').doc(routeRef);
    final DocumentSnapshot mainDoc = await docRef.get();
    final CollectionReference terminalColRef = mainDoc.reference.collection('terminals');
    final QuerySnapshot terminalQuerySnapshot = await terminalColRef.get();
    final List<QueryDocumentSnapshot> terminalDocs = terminalQuerySnapshot.docs;
    for (var terminalDoc in terminalDocs) {
      if (terminalDoc['terminal_id'] == terminalID) {
        final CollectionReference requestColRef = terminalDoc.reference.collection('requests');
        final String docID =
            '@${terminalDoc['terminal_name']}@${DateTime.now().millisecondsSinceEpoch}@${Random.secure().nextInt(100)}@';
        final DocumentReference newDocRef = requestColRef.doc(docID);
        newDocRef.set({
          'request_time': DateTime.now().toString(),
        });
      }
    }
  }

  Stream<QuerySnapshot> getAllDrivers() {
    return _db.collection('drivers').snapshots();
  }

  Future<String> getTerminalName(int terminalID) async {
    final CollectionReference routeColRef = _db.collection('routes');
    final QuerySnapshot querySnapshot = await routeColRef.get();
    final List<QueryDocumentSnapshot> routeDocs = querySnapshot.docs;

    for (var doc in routeDocs) {
      final CollectionReference terminalColRef = doc.reference.collection('terminals');
      final QuerySnapshot querySnapshot = await terminalColRef.get();
      final List<QueryDocumentSnapshot> terminalDocs = querySnapshot.docs;
      for (var doc in terminalDocs) {
        if (doc['terminal_id'] == terminalID) {
          return doc['terminal_name'];
        }
      }
    }
    return '';
  }

  // works perfectly
  Future<List<String>> getAllTerminalIDs() async {
    List<String> terminalIDs = [];

    final CollectionReference routeColRef = _db.collection('routes');
    final QuerySnapshot querySnapshot = await routeColRef.get();
    final List<QueryDocumentSnapshot> routeDocs = querySnapshot.docs;

    for (var doc in routeDocs) {
      final CollectionReference terminalColRef = doc.reference.collection('terminals');
      final QuerySnapshot querySnapshot = await terminalColRef.get();
      final List<QueryDocumentSnapshot> terminalDocs = querySnapshot.docs;

      for (var doc in terminalDocs) {
        terminalIDs.add(doc['terminal_id'].toString());
      }
    }
    return terminalIDs;
  }

  Future<List<RouteInfo>> getRoutes(String terminalID) async {
    List<RouteInfo> routes = [];
    List<Terminal> terminals = [];
    List<Request> requests = [];

    final CollectionReference routeColRef = _db.collection('routes');
    final QuerySnapshot querySnapshot = await routeColRef.get();
    final List<QueryDocumentSnapshot> routeDocs = querySnapshot.docs;
    final List<QueryDocumentSnapshot> requiredRouteDocs = [];

    for (var routeDoc in routeDocs) {
      final terminalColRef = routeDoc.reference.collection('terminals');
      final QuerySnapshot terminalQuerySnapshot = await terminalColRef.get();
      final List<QueryDocumentSnapshot> terminalDocs = terminalQuerySnapshot.docs;
      bool exist = terminalDocs.any((element) => element['terminal_id'] == int.parse(terminalID));
      if (exist) requiredRouteDocs.add(routeDoc);
    }

    for (var routeDoc in requiredRouteDocs) {
      final terminalColRef = routeDoc.reference.collection('terminals');
      final QuerySnapshot terminalQuerySnapshot = await terminalColRef.get();
      final List<QueryDocumentSnapshot> terminalDocs = terminalQuerySnapshot.docs;
      for (var terminalDoc in terminalDocs) {
        final requestColRef = terminalDoc.reference.collection('requests');
        final QuerySnapshot requestQuerySnapshot = await requestColRef.get();
        final List<QueryDocumentSnapshot> requestDocs = requestQuerySnapshot.docs;
        for (var requestDoc in requestDocs) {
          requests.add(Request(requestTime: requestDoc['request_time']));
        }
        terminals.add(Terminal(
          terminalID: terminalDoc['terminal_id'],
          terminalName: terminalDoc['terminal_name'],
          requests: requests,
          terminalLocation: TerminalLocation(
            latitude: terminalDoc['terminal_location']['terminal_latitude'],
            longitude: terminalDoc['terminal_location']['terminal_longitude'],
          ),
        ));
      }
      //here
      routes.add(RouteInfo(
        reference: routeDoc.id,
        fromTerminal: routeDoc['from_terminal'],
        toTerminal: routeDoc['to_terminal'],
        routeTerminals: terminals,
      ));
    }
    return routes;
  }

  void updateTerminalLocation(String terminalID) async {
    final QuerySnapshot routeQuerySnapshot = await _db.collection('routes').get();
    final List<QueryDocumentSnapshot> routeDocs = routeQuerySnapshot.docs;
    for (var routeDoc in routeDocs) {
      final QuerySnapshot terminalQuerySnapshot =
          await routeDoc.reference.collection('terminals').get();
      final List<QueryDocumentSnapshot> terminalDocs = terminalQuerySnapshot.docs;
      for (var terminalDoc in terminalDocs) {
        if (terminalDoc['terminal_id'] == int.parse(terminalID)) {
          final String routeRef = routeDoc.id;
          final String terminalRef = terminalDoc.id;
          final Position? position = await locationManager.getCurrentLocation();
          if (position == null) return;
          await _db
              .collection('routes')
              .doc(routeRef)
              .collection('terminals')
              .doc(terminalRef)
              .update({
            'terminal_location': {
              'terminal_latitude': position.latitude, // to be updated
              'terminal_longitude': position.longitude // to be updated
            }
          });
        }
      }
    }
  }
}
