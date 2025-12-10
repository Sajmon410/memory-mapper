import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget{
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
  }
  class _MapScreenState extends State<MapScreen> {
    GoogleMapController? _mapController;
    Location location = Location();
    LatLng? _currentLatLng;

    @override
    void initState(){
      super.initState();
      _getCurrentLocation();
    }

    Future<void> _getCurrentLocation() async {
      final locData = await location.getLocation();
      setState((){
        _currentLatLng = LatLng(locData.latitude!, locData.longitude!);
      });
    }

  @override
  Widget build(BuildContext context){
  return Scaffold(
    appBar: AppBar(title: const Text("Memory Mapper")),
    body: _currentLatLng == null
    ? const Center(child:CircularProgressIndicator())
    :GoogleMap(
      initialCameraPosition:  CameraPosition(
        target: _currentLatLng!,
        zoom: 15),
    myLocationEnabled: true,
    myLocationButtonEnabled: true,
    ),
  );
  }
}