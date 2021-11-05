import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:location/location.dart';

import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:teamtrack/components/PlatformGraphics.dart';
import 'dart:async';

import 'package:teamtrack/models/AppModel.dart';
import 'package:teamtrack/models/GameModel.dart';

class TemplatesList extends StatefulWidget {
  TemplatesList({Key? key}) : super(key: key);

  @override
  _TemplatesListState createState() => _TemplatesListState();
}

class _TemplatesListState extends State<TemplatesList> {
  late GoogleMapController mapController;
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(37, -122),
    zoom: 11.5,
  );
  Location location = new Location();

  Geoflutterfire geo = Geoflutterfire();

  // Stateful Data
  BehaviorSubject<double> radius = BehaviorSubject();
  Set<Marker> markers = Set();

  // Subscription
  late StreamSubscription subscription;
  @override
  initState() {
    super.initState();
    radius.add(100);
  }

  Widget build(context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: LatLng(37, -122), zoom: 15),
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          mapType: MapType.normal,
          compassEnabled: true,
          markers: markers,
          zoomControlsEnabled: false,
        ),
        Positioned(
          bottom: 50,
          left: 10,
          child: PlatformSlider(
            min: 100.0,
            max: 500.0,
            divisions: 4,
            value: radius.value,
            label: 'Radius ${radius.value}km',
            activeColor: Colors.green,
            inactiveColor: Colors.green.withOpacity(0.2),
            onChanged: _updateQuery,
          ),
        )
      ],
    );
  }

  // Map Created Lifecycle Hook
  _onMapCreated(GoogleMapController controller) {
    _startQuery();
    setState(() {
      mapController = controller;
    });
  }

  // Set GeoLocation Data
  Future<void> _addGeoPoint(Event event) async {
    var pos = await location.getLocation();
    GeoFirePoint point =
        geo.point(latitude: pos.latitude ?? 0, longitude: pos.longitude ?? 0);
    final newEvent = Event.fromJson(event.toJson());
    newEvent.shared = true;
    var newEventJson = newEvent.toJson();
    newEventJson['position'] = point.data;

    return firebaseFirestore
        .collection('templates')
        .doc(event.id)
        .set(newEventJson);
    // .add(newEventJson);
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    print(documentList);
    // mapController.clearMarkers();
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint pos = (document.data() as Map?)?['position']['geopoint'];
      double distance = (document.data() as Map?)?['distance'];
      var marker = Marker(
        markerId: MarkerId(document.id),
        position: LatLng(pos.latitude, pos.longitude),
        icon: BitmapDescriptor.defaultMarker,
      );

      // mapController.addMarker(marker);
      markers.add(marker);
    });
  }

  _startQuery() async {
    // Get users location
    var pos = await location.getLocation();
    final lat = pos.latitude;
    final lng = pos.longitude;

    // Make a referece to firestore
    final ref = firebaseFirestore.collection('templates');
    GeoFirePoint center = geo.point(latitude: lat ?? 0, longitude: lng ?? 0);

    // subscribe to query
    subscription = radius.switchMap((rad) {
      return geo.collection(collectionRef: ref).within(
          center: center, radius: rad, field: 'position', strictMode: true);
    }).listen(_updateMarkers);
  }

  _updateQuery(value) {
    final zoom = -0.02 * value + 14.0;
    mapController.moveCamera(CameraUpdate.zoomTo(zoom));
    setState(() {
      radius.add(value);
    });
  }

  @override
  dispose() {
    subscription.cancel();
    mapController.dispose();
    super.dispose();
  }
}
