import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:teamtrack/views/home/events/EventView.dart';
import 'package:teamtrack/views/home/events/EventsList.dart';
import 'package:provider/provider.dart';

class TemplatesList extends StatefulWidget {
  TemplatesList({Key? key, required this.superState}) : super(key: key);
  final State superState;
  @override
  _TemplatesListState createState() => _TemplatesListState();
}

class _TemplatesListState extends State<TemplatesList> {
  late GoogleMapController mapController;
  Location location = new Location();

  Geoflutterfire geo = Geoflutterfire();

  // Stateful Data
  BehaviorSubject<double> radius = BehaviorSubject.seeded(100);
  Set<Marker> markers = Set();

  // Subscription
  late StreamSubscription subscription;
  LocationData? currentLocation;
  final center = MarkerId('curr');

  @override
  Widget build(context) => FutureBuilder<LocationData>(
        future: location.getLocation(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: PlatformProgressIndicator());
          currentLocation = snapshot.data;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    snapshot.data?.latitude ?? 0,
                    snapshot.data?.longitude ?? 0,
                  ),
                  zoom: 12,
                ),
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
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
                        max: 300.0,
                        divisions: 2,
                        value: radius.value,
                        label: 'Radius ${radius.value} km',
                        activeColor: Colors.green,
                        inactiveColor: Colors.green.withOpacity(0.2),
                        onChanged: _updateQuery,
                      ),
                    ),
                    if (!(context.read<User?>()?.isAnonymous ?? true))
                      FloatingActionButton(
                        onPressed: _addGeoPoint,
                        child: Icon(
                          Icons.add,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      );

  // Map Created Lifecycle Hook
  void _onMapCreated(GoogleMapController controller) {
    _startQuery();
    setState(() {
      mapController = controller;
    });
  }

  Future<LatLng> getCenter() => mapController.getVisibleRegion().then(
        (value) => LatLng(
            (value.northeast.latitude + value.southwest.latitude) / 2,
            (value.northeast.longitude + value.southwest.longitude) / 2),
      );

  // Set GeoLocation Data
  void _addGeoPoint() async {
    final center = await getCenter();
    GeoFirePoint point = geo.point(
      latitude: center.latitude,
      longitude: center.longitude,
    );
    await showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        child: EventsList(
          onTap: (event) async {
            final newEvent = Event.fromJson(
              event.toJson(),
            );
            var newEventJson = newEvent.toJson();
            newEventJson['position'] = point.data;
            newEventJson.remove('id');
            newEventJson.remove('shared');
            newEventJson['createdAt'] = FieldValue.serverTimestamp();
            Navigator.of(context).pop();
            showPlatformDialog(
              barrierDismissible: false,
              context: context,
              builder: (_) => PlatformAlert(
                content: Center(
                  child: PlatformProgressIndicator(),
                ),
              ),
            );
            final ref = await firebaseFirestore
                .collection('templates')
                .add(newEventJson);
            Navigator.of(context).pop();
            setState(
              () => markers.add(
                Marker(
                  markerId: MarkerId(ref.id),
                  position: LatLng(point.latitude, point.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                  onTap: () async {
                    await subscription.cancel();
                    mapController.dispose();
                    await Navigator.push(
                      context,
                      platformPageRoute(builder: (_) {
                        final event = newEvent;
                        event.shared = false;
                        return EventView(
                          event: event,
                          isPreview: true,
                        );
                      }),
                    );
                    widget.superState.setState(dataModel.saveEvents);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) async {
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint pos = (document.data() as Map?)?['position']['geopoint'];
      var marker = Marker(
        markerId: MarkerId(document.id),
        position: LatLng(pos.latitude, pos.longitude),
        icon: BitmapDescriptor.defaultMarker,
        onTap: () async {
          await subscription.cancel();
          mapController.dispose();
          await Navigator.push(
            context,
            platformPageRoute(builder: (_) {
              final event =
                  Event.fromJson(document.data() as Map<String, dynamic>);
              event.shared = false;
              return EventView(
                event: event,
                isPreview: true,
              );
            }),
          );
          await dataModel.saveEvents();
          widget.superState.setState(() {});
        },
      );
      markers.add(marker);
    });
  }

  void _startQuery() async {
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

  void _updateQuery(double value) {
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
  void dispose() {
    subscription.cancel();
    mapController.dispose();
    super.dispose();
  }
}
