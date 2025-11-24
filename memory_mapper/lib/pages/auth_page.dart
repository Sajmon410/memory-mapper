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

  Future<void> _confirmSignUp() async {
   try{
      final res = await Amplify.Auth.confirmSignUp(
        username: _emailController.text.trim(),
         confirmationCode: _codeController.text.trim());
         setState(()=> _status = "Confirm reuslts: ${res.isSignUpComplete}");
   } catch (e){
      setState(() => _status = "Error $e");
   }
  }
  Future <void> _signIn() async {
    try{
      final res = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim());
        setState(() => _status = "Signed in: ${res.isSignedIn}");
    }catch(e){
      setState(() => _status = "Error $e");
    }
  }
  Future <void> _signOut() async{
    await Amplify.Auth.signOut();
    setState(()=> _status = "Signed out");

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Memmory Mapper")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _nameController,decoration: const InputDecoration(labelText: "Name")),
          TextField(controller: _emailController,decoration: const InputDecoration(labelText: "Email")),
          TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"),obscureText: true,),
          TextField(controller: _codeController,decoration: const InputDecoration(labelText: "Confirmation Code"),),
          const SizedBox(height: 20,),
          ElevatedButton(onPressed: _singUp, child: const Text("Sign Up")),
          ElevatedButton(onPressed: _confirmSignUp, child: const Text("Confirm Sign Up")),
          ElevatedButton(onPressed: _signIn, child: const Text("Sign In")),
          ElevatedButton(onPressed: _signOut, child: const Text("Sign Out")),
          const SizedBox(height: 20,),
          Text(_status),
          ],
        ),
      ),
    );
  }
}