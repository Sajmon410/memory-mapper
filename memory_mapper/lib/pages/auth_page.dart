import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:flutter/material.dart';

import 'map_screen.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: Authenticator.builder(),
        home: const MapScreen(),
      ),
    );
  }
}
