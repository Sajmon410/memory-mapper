import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class MapScreen extends StatefulWidget{
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
  }
  class _MapScreenState extends State<MapScreen> {
    GoogleMapController? _mapController;
    Location location = Location();
    LatLng? _currentLatLng;
    String? _userName;

    @override
    void initState(){
      super.initState();
      _getCurrentLocation();
      _getCurrentUser();
    }

    Future<void> _getCurrentLocation() async {
      final locData = await location.getLocation();
      setState((){
        _currentLatLng = LatLng(locData.latitude!, locData.longitude!);
      });
    }

    Future<void> _getCurrentUser() async{
      try{
        final attributes = await Amplify.Auth.fetchUserAttributes();
        final nameAttr = attributes.firstWhere(
          (attr)=> attr.userAttributeKey.key == 'name',
          orElse:()=> const AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.name, value: 'Unknown')
        );
        setState(() {
          _userName = nameAttr.value;
        });
      } catch(e){
        safePrint('Error fetching user: $e');
      }
    }

    Future<void> _signOut() async {
        try{
          final result = await Amplify.Auth.signOut();
          if(result is CognitoCompleteSignOut){
            safePrint('Sign out is completet succesfully!');
          } else if (result is CognitoFailedSignOut){
            safePrint("Error signing user out: ${result.exception.message}");
          }
        } on AuthException catch(e){
          safePrint('Error signing out: ');
        }
    }

  @override
  Widget build(BuildContext context){
  return Scaffold(
    appBar: AppBar(
      title: Text("Welcome $_userName!",
      style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.deepPurpleAccent,
      actions: [
        IconButton(icon: Icon(Icons.logout),
        onPressed: (){
          _signOut();
        },tooltip:'Logout'
        ),
      ],
      ),
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