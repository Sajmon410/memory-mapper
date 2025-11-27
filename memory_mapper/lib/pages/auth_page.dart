import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }
  void _configureAmplify() async {
    final authPlugin = AmplifyAuthCognito();
    Amplify.addPlugin(authPlugin);
    try {
      await Amplify.configure(amplifyconfig);
      print('Amplify configured successfully');
    } on Exception catch (e) {
      print('Error configuring Amplify: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Amplify Cognito with Flutter'),
      ),
      body: Center(
        child: Authenticator(), // Using Authenticator Widget for UI
      ),
    );
  }
}