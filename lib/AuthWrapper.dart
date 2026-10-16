import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:krushi/Homepage.dart';
import 'package:krushi/Login.dart';

class Authwrapper extends StatefulWidget {
  const new({super.key});

  @override
  State<Authwrapper> createState() => _AuthwrapperState();
}

class _AuthwrapperState extends State<Authwrapper> {
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  @override
  Widget build(BuildContext context) {
   return StreamBuilder(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context,Snapshot){
      if(Snapshot.connectionState == ConnectionState.waiting){
        return Scaffold(
          body: CircularProgressIndicator(),
        );
      }
      if(Snapshot.hasData){
          return Homepage();
      }
      return Login();
    }
   );
  }
}