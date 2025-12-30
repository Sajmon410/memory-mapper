import 'dart:convert';
import 'dart:io';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class MapScreen extends StatefulWidget{
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
  }
  class _MapScreenState extends State<MapScreen> {
    Set<Marker> _markers = {};
    GoogleMapController? _mapController;
    Location location = Location();
    LatLng? _currentLatLng;
    String? _userName;
    File? image;
    final picker = ImagePicker();

    @override
    void initState(){
      super.initState();
      _getCurrentLocation();
      _getCurrentUser();
      _loadPins();
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
          safePrint('Error signing out: $e');
        }
    }

    Future<void> _loadPins() async {
 
    final request = GraphQLRequest<String>(
      document: '''
        query ListPins {
          listPins {
            items {
              id
              lat
              lng
              s3Key
              createdAt
            }
          }
        }
      ''',
    );

    final resp = await Amplify.API.query(request: request).response;

    if (resp.data != null) {
      final Map<String, dynamic> data = jsonDecode(resp.data!);
      final List pins = data['listPins']['items'] as List;

    setState(() {
  _markers.add(
    Marker(
      markerId: MarkerId(key),
      position: _currentLatLng!,
      infoWindow: InfoWindow(
        title: 'Photo Pin',
        snippet: DateTime.now().toIso8601String(),
        onTap: () async {
          final urlResult = await Amplify.Storage.getUrl(key: key).result;
          showModalBottomSheet(
            context: context,
            builder: (_) => Image.network(urlResult.url.toString()),
          );
        },
      ),
    ),
  );
  
});
   



    Future<void> createPinWithPhoto(ImageSource source) async {
      final pickedFile = await picker.pickImage(source: source);
      if(pickedFile == null || _currentLatLng == null) return;
      
      final file = AWSFile.fromPath(pickedFile.path);
      final key = 'photos/${DateTime.now().millisecondsSinceEpoch}.jpg';

      //upload
      await Amplify.Storage.uploadFile(localFile: file,key: key);

    final request = GraphQLRequest<String>(
      document: '''
       mutation CreatePin(\$input: CreatePinInput!){
       createPin(input: \$input){ id}
        }
      ''',
      variables: {
        'input':{
          'lat': _currentLatLng!.latitude,
          'lng': _currentLatLng!.longitude,
          's3Key': key,
          'createdAt': DateTime.now().toIso8601String()
        }
      }
    );
    await Amplify.API.mutate(request:   request).response;  

    //refres pins
    await _loadPins();
    }

    // Future<void> pickImage(ImageSource source) async {
    //   final pickedFile = await picker.pickImage(source: source);

    //   if(pickedFile != null){
    //     final file = AWSFile.fromPath(pickedFile.path);

    //     try{
    //       final result = await Amplify.Storage.uploadFile(
    //         localFile: file, 
    //         key: 'photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
    //         );
    //         print("Uploaded: ");
    //     } catch (e) {
    //       print("Error $e");
    //     };
      
    //   } else {
    //     print("No img selected");
    //   }
    // }

    
    // Future<void> listFiles() async {
    //   try{
    //     final operation = Amplify.Storage.list();
    //     final result = await operation.result;
    //     for (var item in result.items){
    //       safePrint('Found file: ${item.key}');
    //     }
    //   } catch (e){
    //     safePrint('Error loading files $e');
    //   }
    // }

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
        color: Colors.white,
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
    markers: _markers,
    myLocationEnabled: true,
    myLocationButtonEnabled: false,
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    floatingActionButton: FloatingActionButton(
      onPressed: ()=> createPinWithPhoto(ImageSource.camera),
      child: Icon(Icons.camera_alt),
      backgroundColor: Colors.deepPurple,
      foregroundColor:  Colors.white,
      ),
  );
  }
}