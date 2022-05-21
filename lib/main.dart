import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frozen2gouser/splashScreen/splash_screen.dart';
import 'package:provider/provider.dart';

import 'dataprovider/appdata.dart';


void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
      MyApp(
          child:MaterialApp(
            title: 'Frozen2Go Users',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home:const MySplashScreen(),
            debugShowCheckedModeBanner: false,
          )
      )
  );
}

class MyApp extends StatefulWidget {
  final Widget? child;
  MyApp({this.child});

  static void Restartapp(BuildContext context){

    context.findAncestorStateOfType<_MyAppState>()!.Restartapp();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Key key= UniqueKey();
  void Restartapp(){
    setState(() {
      UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => AppData(),
        key: key,
        child: widget.child!
    );
  }
}


