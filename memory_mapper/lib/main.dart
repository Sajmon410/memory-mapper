import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized;
  await Amplify.addPlugin(AmplifyAuthCognito());
  await Amplify.configure(amplifyconfig);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
   return MaterialApp(
  debugShowCheckedModeBanner: false, // ovo uklanja "DEBUG" traku
  
);

  }
}


  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      appBar: AppBar(
    
      ),
      body: Center(
     
      ),
    
    );
  }

