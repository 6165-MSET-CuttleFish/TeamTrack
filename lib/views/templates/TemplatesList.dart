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
  Location location = new Location();

  Geoflutterfire geo = Geoflutterfire();

  // Stateful Data
  BehaviorSubject<double> radius = BehaviorSubject.seeded(300);
  Set<Marker> markers = Set();

  // Subscription
  late StreamSubscription subscription;
  LocationData? currentLocation;

  @override
  Widget build(context) {
    return FutureBuilder<LocationData>(
        future: location.getLocation(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return PlatformProgressIndicator();
          currentLocation = snapshot.data;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(snapshot.data?.latitude ?? 0,
                      snapshot.data?.longitude ?? 0),
                  zoom: 7,
                ),
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                mapType: MapType.normal,
                compassEnabled: true,
                markers: markers,
                zoomControlsEnabled: false,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Row(
                  children: [
                    Container(
                      height: 30,
                      child: PlatformSlider(
                        min: 100.0,
                        max: 500.0,
                        divisions: 4,
                        value: radius.value,
                        label: 'Radius ${radius.value} km',
                        activeColor: Colors.green,
                        inactiveColor: Colors.green.withOpacity(0.2),
                        onChanged: _updateQuery,
                      ),
                    ),
                    RawMaterialButton(
                      child: Icon(Icons.pin_drop, color: Colors.white),
                      fillColor: Colors.green,
                      onPressed: _addGeoPoint,
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  // Map Created Lifecycle Hook
  _onMapCreated(GoogleMapController controller) {
    _startQuery();
    setState(() {
      mapController = controller;
    });
  }

  // Set GeoLocation Data
  Future<DocumentReference> _addGeoPoint() async {
    var pos = await mapController.getLatLng(
      ScreenCoordinate(
        x: MediaQuery.of(context).size.width ~/ 2,
        y: MediaQuery.of(context).size.height ~/ 2,
      ),
    );
    GeoFirePoint point = geo.point(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    final newEvent = Event.fromJson(Event(
      name: "Test Event",
      type: EventType.local,
      gameName: Statics.gameName,
    ).toJson());
    newEvent.shared = true;
    var newEventJson = newEvent.toJson();
    newEventJson['position'] = point.data;

    return firebaseFirestore.collection('templates').add(newEventJson);
    // .add(newEventJson);
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    print(documentList);
    // mapController.clearMarkers();
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint pos = (document.data() as Map?)?['position']['geopoint'];
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
    var pos = currentLocation;
    final lat = pos?.latitude;
    final lng = pos?.longitude;

    // Make a referece to firestore
    final ref = firebaseFirestore.collection('templates');
    GeoFirePoint center = geo.point(latitude: lat ?? 0, longitude: lng ?? 0);

    // subscribe to query
    subscription = radius.switchMap((rad) {
      return geo.collection(collectionRef: ref).within(
            center: center,
            radius: rad,
            field: 'position',
            strictMode: true,
          );
    }).listen(_updateMarkers);
  }

  _updateQuery(double value) {
    final zoomMap = {
      100.0: 12.0,
      200.0: 10.0,
      300.0: 7.0,
      400.0: 6.0,
      500.0: 5.0
    };
    final zoom = zoomMap[value];
    mapController.moveCamera(CameraUpdate.zoomTo(zoom ?? 0));
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
