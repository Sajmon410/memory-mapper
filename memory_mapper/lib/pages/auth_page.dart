import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  
  @override
  State<StatefulWidget> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  String _status = "";

  Future <void> _singUp() async {
    try {
      final res = await Amplify.Auth.signUp
      (
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        options: CognitoSignUpOptions(userAttributes: {
        CognitoUserAttributeKey.email: _emailController.text.trim(),
        CognitoUserAttributeKey.name: _nameController.text.trim(),
        }),
      );
    setState(()=> _status = "Sign up Started: ${res.isSignUpComplete}");
  } catch (e) {
    setState(()=> _status = "Error $e");
  }
}

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}