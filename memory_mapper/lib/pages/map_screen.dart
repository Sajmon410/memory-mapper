import 'dart:convert';
import 'dart:io';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:custom_info_window/custom_info_window.dart';
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
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  @override
  void initState() {
    super.initState();
    _checkUser();
    _getCurrentLocation();
    _getCurrentUser();
    _loadPins();
  }
  Future<void> _checkUser()async {
    try{
      final user = await Amplify.Auth.getCurrentUser();
      safePrint('Current user: ${user.username}');
    } catch (e) {
      safePrint('Error fetching current user: $e');
    }
  }
  Future<void> _getCurrentLocation() async {
    final locData = await location.getLocation();
    setState(() {
      _currentLatLng = LatLng(locData.latitude!, locData.longitude!);
    });
  }

  Future<void> _getCurrentUser() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final nameAttr = attributes.firstWhere(
        (attr) => attr.userAttributeKey.key == 'name',
        orElse: () => const AuthUserAttribute(
            userAttributeKey: CognitoUserAttributeKey.name, value: 'Unknown'),
      );
      setState(() {
        _userName = nameAttr.value;
      });
    } catch (e) {
      safePrint('Error fetching user: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      final result = await Amplify.Auth.signOut();
      if (result is CognitoCompleteSignOut) {
        safePrint('Sign out completed successfully!');
      } else if (result is CognitoFailedSignOut) {
        safePrint("Error signing user out: ${result.exception.message}");
      }
    } on AuthException catch (e) {
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
        _markers = pins.map((p) {
          return Marker(
            markerId: MarkerId(p['id']),
            position: LatLng(p['lat'], p['lng']),
            onTap: () => _showInfoWindow(p['id'], p['s3Key'], LatLng(p['lat'], p['lng']), p['createdAt']),
          );
        }).toSet();
      });
    }
  }

  Future<void> createPinWithPhoto(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null || _currentLatLng == null) return;

    final file = AWSFile.fromPath(pickedFile.path);
    final key = 'photos/${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
    // Upload
    await Amplify.Storage.uploadFile(localFile: file, key: key);

    final String timestamp = "${DateTime.now().toIso8601String().split('.').first}Z";

    // Mutation
    final request = GraphQLRequest<String>(
      document: '''
        mutation CreatePin(\$input: CreatePinInput!) {
          createPin(input: \$input) { id }
        }
      ''',
      variables: {
        'input': {
          'lat': _currentLatLng!.latitude,
          'lng': _currentLatLng!.longitude,
          's3Key': key,
          'createdAt': timestamp,
        }
      },
    );
    final resp = await Amplify.API.mutate(request: request).response;
  
     if(resp.data!=null){
       await _loadPins();
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pin created successfully!')),
      );
     }
    } catch (e) {
      safePrint('Error creating pin: $e');
  }}

  Future<void> deletePin(String id, String s3Key) async {
    try{
      final request = GraphQLRequest<String>(
        document: '''
          mutation DeletePin(\$input: DeletePinInput!) {
          deletePin(input: \$input) { id }
        }
      ''',
      variables: {
        'input': {'id': id}
      },
      );

      final response = await Amplify.API.mutate(request: request).response;
      if(response.hasErrors){
        safePrint('Greska pri brisanju iz baze: ${response.errors}');
        return;
      }
      Amplify.Storage.remove(key: s3Key);
      setState((){
        _markers.removeWhere((m) => m.markerId.value == id);
      });
      _customInfoWindowController.hideInfoWindow!();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pin deleted successfully!')),
      );
    } catch (e) {
      safePrint('Error deleting pin: $e');
    }
  }

  Future<void> _showInfoWindow(String dbId,String s3Key , LatLng position, String dateTime) async {
    String formattedTime = dateTime.split('.').first.replaceAll(RegExp(r'[TZ]'), ' ');

    final urlResult= await Amplify.Storage.getUrl(key: s3Key).result;
    final imageUrl = urlResult.url.toString();

    _customInfoWindowController.addInfoWindow!(
      Container(
        width: 200,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.deepPurple),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Balkanska Fotografija', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(formattedTime, style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
              imageUrl, 
              width: double.infinity,
              fit: BoxFit.cover,
              
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.error, color: Colors.red));
              },
              ),
            ),

              ),
            Row(children: [
              Expanded(child: SizedBox(height: 30, child: 
              ElevatedButton(
              onPressed: () async {
                final urlResult = await Amplify.Storage.getUrl(key: s3Key).result;
                showModalBottomSheet(
                  context: context,
                  builder: (_) => Image.network(urlResult.url.toString()),
                );   
              },
              child: const Text('View Photo'),
            ),),),
            const SizedBox(width: 5),
             IconButton(
              icon: const Icon(Icons.delete_outline, color: Color.fromARGB(255, 235, 121, 113), size: 20),
              onPressed: () {
                deletePin(dbId, s3Key);
              },
            ),
            ],
        ),
      ]),
      ),),
      position,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome $_userName!",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _currentLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : Stack( children:[
          GoogleMap(
            onTap: (position){
              _customInfoWindowController.hideInfoWindow!();
            },
            onMapCreated: (GoogleMapController controller){
              _customInfoWindowController.googleMapController = controller;
              _mapController = controller;
            },
              initialCameraPosition: CameraPosition(
                target: _currentLatLng!,
                zoom: 15,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),
            CustomInfoWindow(
            controller: _customInfoWindowController,
            height: 280,
            width: 200,
            offset: 50,
            ),
            ]) ,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => createPinWithPhoto(ImageSource.camera),
        child: const Icon(Icons.camera_alt),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}

    