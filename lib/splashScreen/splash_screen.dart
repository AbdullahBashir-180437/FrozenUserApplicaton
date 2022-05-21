import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frozen2gouser/mainScreens/main_screen.dart';


import '../Global/global.dart';
import '../authenication/login_screen.dart';



class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {

 startTimer()
 {
   Timer(const Duration(seconds : 2), ()async
   {if(await fAuth.currentUser !=null)
   { currentFirebaseUser = fAuth.currentUser;
   Navigator.push(context, MaterialPageRoute(builder: (c)=> MainScreen()));
   }
   else {
     Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
   }
         } );
 }
 @override
  void initState() {
    // TODO: implement initState
    super.initState();

    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.lightBlue,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("images/logo.jpg"),

            const SizedBox(height: 15,),

            const Text("Frozen2Go User Application",
            style: TextStyle(
              fontSize: 25,
              color: Colors.white,
              fontWeight: FontWeight.bold,

            ),)
          ],
        ),
      ),
    );
  }
}
