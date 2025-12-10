import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';
import 'pages/auth_page.dart';

Future<void> _configureAmplify() async {
  if (!Amplify.isConfigured) {
    try {
      await Amplify.addPlugin(AmplifyAuthCognito());
      await Amplify.configure(amplifyconfig);
      safePrint('Successfully Configured.');
    } on Exception catch (e) {
      safePrint('Error Configuring Amplify: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
   return const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: AuthPage(),
);

  }
}


