import 'dart:async';
import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:frozen2gouser/datamodels/directiondetails.dart';
import 'package:frozen2gouser/datamodels/nearbydrivers.dart';
import 'package:frozen2gouser/globalvariable.dart';
import 'package:frozen2gouser/helper/firehelper.dart';
import 'package:frozen2gouser/helper/helpermethod.dart';
import 'package:frozen2gouser/main.dart';
import 'package:frozen2gouser/mainScreens/searchpage.dart';
import 'package:frozen2gouser/mainScreens/temperature_tab.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../Global/global.dart';
import '../authenication/login_screen.dart';
import '../brand_colors.dart';
import '../dataprovider/appdata.dart';
import '../helper/Requesthelper.dart';
import '../splashScreen/splash_screen.dart';
import '../styles/styles.dart';
import '../widget/BrandDivier.dart';
import '../widget/ProgressDialog.dart';
import 'drowsiness_tab.dart';
 class MainScreen extends StatefulWidget {
   @override
   State<MainScreen> createState() => _MainScreenState();
 }

 class _MainScreenState extends State<MainScreen>  with TickerProviderStateMixin{
   GlobalKey<ScaffoldState> scaffoldkey = new GlobalKey<ScaffoldState>();
   Completer<GoogleMapController> _controller = Completer();

   double ridedetailsheetheight = 0;
   double searchsheetheight =0;
   double requestingsheetHeight=0;




   late GoogleMapController mapController;
   double mapBottomPadding = 0;
   double maptopPadding = 0;


   List<LatLng> polylineCoordinates = [];
   Set<Polyline> _polylines = {};
   Set<Marker> _Markers = {};
   Set<Circle> _Circles = {};

   bool drawerCanOpen = true;


   var geolocator = Geolocator();
   late Position currentPosition;

   var destinationController = TextEditingController();
   var Temperature = TextEditingController();
   var warehouse = TextEditingController();


   var focusDestination = FocusNode();
   bool focused = false;

  DirectionDetails? tripDirectionDetails;

  DatabaseReference? rideRef;


   void SetFocus() {
     if (!focused) {
       FocusScope.of(context).requestFocus(focusDestination);
       focused = true;
     }
   }

   BitmapDescriptor? nearbyIcon;


   bool nearbyDriverskeysloaded = false;

   void updatedriversonMap() {
     setState(() {
       _Markers.clear();
     });
     Set<Marker> tempMarkers = Set<Marker>();
     for (NearbyDriver driver in firehelper.nearbydriverlist) {
       LatLng driverPosition = LatLng(driver.latitude, driver.longitude);
       Marker thisMarker = Marker(
         markerId: MarkerId('Drivers${driver.key}'),
         position: driverPosition,
         icon: nearbyIcon!,
         rotation: generateRandomNumber(360),
       );
       tempMarkers.add(thisMarker);
     }
     setState(() {
       _Markers = tempMarkers;
     });
   }

   double generateRandomNumber(int max) {
     var randomGenerator = Random();
     int radint = randomGenerator.nextInt(max);
     return radint.toDouble();
   }

   void startGeofireListener() {
     Geofire.initialize('driversavailable');
     Geofire.queryAtLocation(
         currentPosition.latitude, currentPosition.longitude, 50)?.listen((
         map) {
       print(map);

       if (map != null) {
         var callBack = map['callBack'];

         //latitude will be retrieved from map['latitude']
         //longitude will be retrieved from map['longitude']

         switch (callBack) {
           case Geofire.onKeyEntered:
             NearbyDriver nearbyDriver = NearbyDriver(
                 map['key'], map['latitude'], map['longitude']);
             nearbyDriver.key = map['key'];
             nearbyDriver.latitude = map['latitude'];
             nearbyDriver.longitude = map['longitude'];
             if (nearbyDriverskeysloaded) {
               updatedriversonMap();
             }

             firehelper.nearbydriverlist.add(nearbyDriver);

             break;

           case Geofire.onKeyExited:
             firehelper.removeFromlist(map['key']);
             updatedriversonMap();
             break;

           case Geofire.onKeyMoved:
             NearbyDriver nearbyDriver = NearbyDriver(
                 map['key'], map['latitude'], map['longitude']);
             nearbyDriver.key = map['key'];
             nearbyDriver.latitude = map['latitude'];
             nearbyDriver.longitude = map['longitude'];

             firehelper.updatenearbylocation(nearbyDriver);
             updatedriversonMap();
             break;

           case Geofire.onGeoQueryReady:
             print(map['result']);
             print('firehelper lenght: ${firehelper.nearbydriverlist.length}');
             nearbyDriverskeysloaded = true;
             updatedriversonMap();

             break;
         }
       }

       setState(() {});
     });
   }


   void setupPostionlocator() async {
     LocationPermission permission;
     permission = await Geolocator.requestPermission();
     Position position = await Geolocator.getCurrentPosition(
         desiredAccuracy: LocationAccuracy.bestForNavigation);
     currentPosition = position;

     LatLng pos = LatLng(position.latitude, position.longitude);
     CameraPosition cp = new CameraPosition(target: pos, zoom: 14);
     mapController.animateCamera(CameraUpdate.newCameraPosition(cp));

     String address = await HelperMethods.findCordinateAddress(
         position, context);
     print(address);

     startGeofireListener();
   }

   static final CameraPosition _kLake = CameraPosition(
       bearing: 192.8334901395799,
       target: LatLng(37.43296265331129, -122.08832357078792),
       tilt: 59.440717697143555,
       zoom: 19.151926040649414);

   void showDetailsheet() async
   {
     await getDirection();
     setState(() {
       searchsheetheight = 0;
       ridedetailsheetheight=275;
       mapBottomPadding=230;
       drawerCanOpen = false;

     });
   }
   void showRequestingSheet(){
     setState(() {

       ridedetailsheetheight = 0;
       requestingsheetHeight = 220;
       mapBottomPadding = 190;
       drawerCanOpen = true;

     });

     //createRideRequest();
   }
   void createMarker(){
     if(nearbyIcon == null){

       ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(1,1));
       BitmapDescriptor.fromAssetImage(
           imageConfiguration,'images/pickup.png'
       ).then((icon){
         nearbyIcon = icon;
       });
     }
   }

   @override
   void initstate(){
     super.initState();
     HelperMethods.getCurrentUserInfo();
   }

   @override


   Widget build(BuildContext context) {
     createMarker();
     return Scaffold(
       key: scaffoldkey,
       drawer: Container(
         width: 250,
         color: Colors.white,
         child: Drawer(

           child: ListView(
             padding: EdgeInsets.all(0),
             children: <Widget>[

               Container(
                 color: Colors.white,
                 height: 160,
                 child: DrawerHeader(
                   decoration: BoxDecoration(
                       color: Colors.white
                   ),
                   child: Row(
                     children: <Widget>[
                       Image.asset('images/user.png', height: 60, width: 60,),
                       SizedBox(width: 15,),

                       Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: <Widget>[
                           Text('Abdullah Bashir', style: TextStyle(
                               fontSize: 20, fontFamily: 'Brand-Bold'),),
                           SizedBox(height: 5,),
                           Text('View Profile'),
                         ],
                       )

                     ],
                   ),
                 ),
               ),
               BrandDivider(),

               SizedBox(height: 10,),

               ListTile(
                 leading: Icon(Icons.thermostat),
                 title: Text('Temperature', style: kDrawerItemStyle,),
                 onTap: () =>
                     Navigator.push(context, MaterialPageRoute(builder: (c)=> TemperatureTabPage())),
               ),

               ListTile(
                 leading: Icon(Icons.supervised_user_circle),
                 title: Text('Drowsiness', style: kDrawerItemStyle,),
                 onTap: () =>
                     Navigator.push(context, MaterialPageRoute(builder: (c)=> drwosinessTabPage())),

               ),

               ListTile(
                 leading: Icon(Icons.contact_support),
                 title: Text('Support', style: kDrawerItemStyle,),
               ),

               ListTile(
                 leading: Icon(Icons.logout),
                 title: Text('logout', style: kDrawerItemStyle,),
                   onTap:() {
               fAuth.signOut();
               Navigator.push(context,MaterialPageRoute(builder: (c)=> const MySplashScreen()));
               },
               ),

             ],
           ),
         ),


       ),

       body: Stack(
         children: <Widget>[
           GoogleMap(
             padding: EdgeInsets.only(
                 bottom: mapBottomPadding, top: maptopPadding),
             mapType: MapType.normal,
             myLocationButtonEnabled: true,
             initialCameraPosition: _kLake,
             myLocationEnabled: true,
             zoomGesturesEnabled: true,
             zoomControlsEnabled: true,
             polylines: _polylines,
             markers: _Markers,
             circles: _Circles,


             onMapCreated: (GoogleMapController controller) {
               _controller.complete(controller);
               mapController = controller;

               setState(() {
                 maptopPadding = 30;
                 mapBottomPadding = 250;
               });
               setupPostionlocator();
             },
           ),
           Positioned(
             top: 44,
             left: 20,
             child: GestureDetector(
               onTap: () {
                 if(drawerCanOpen){
                 scaffoldkey.currentState?.openDrawer();}
                 else{
                   resetApp();
                 }
               },
               child: Container(
                 decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(20),
                     boxShadow: [
                       BoxShadow(
                           color: Colors.black26,
                           blurRadius: 5.0,
                           spreadRadius: 0.5,
                           offset: Offset(0.7, 0.7,)
                       )
                     ]

                 ),
                 child: CircleAvatar(
                   backgroundColor: Colors.white,
                   radius: 20,
                   child: Icon( (drawerCanOpen)? Icons.menu:Icons.arrow_back),
                 ),
               ),
             ),
           ),
       Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSize(
          duration: new Duration(milliseconds: 150),
          child: Container(
          decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
          boxShadow: [
          BoxShadow(
          color: Colors.black26,
          blurRadius: 15.0, // soften the shadow
          spreadRadius: 0.5, //extend the shadow
          offset: Offset(0.7,0.7, // Move to bottom 10 Vertically
              ),
            )
          ],
     ),

                 child: Padding(
                   padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: <Widget>[
                       SizedBox(height: 5,),
                       Text('Welcome To Frozen2Go',
                         style: TextStyle(fontSize: 10),),
                       Text('Where You want Your Order to be Delivered',
                         style: TextStyle(
                             fontSize: 18, fontFamily: 'Brand-Bold'),),

                       SizedBox(height: 20,),
                       GestureDetector(
                         onTap: () async {
                           var response = await Navigator.push(
                               context, MaterialPageRoute(
                               builder: (context) => SearchPage()
                           ));

                           if (response == 'getDirection') {
                             showDetailsheet();
                           }
                         },
                         child: Positioned(
                           left:0,
                           right:0,
                           bottom:0,
                           child: AnimatedSize(
                             vsync: this,
                             duration: new Duration(milliseconds:150),
                             curve:Curves.easeIn,
                             child: Container(
                               decoration: BoxDecoration(
                                   color: Colors.white,
                                   borderRadius: BorderRadius.circular(4),
                                   boxShadow: [
                                     BoxShadow(
                                         color: Colors.black12,
                                         blurRadius: 5.0,
                                         spreadRadius: 0.5,
                                         offset: Offset(
                                           0.7,
                                           0.7,
                                         )
                                     )
                                   ]
                               ),
                               child: Padding(
                                 padding: EdgeInsets.all(12.0),
                                 child: Row(
                                   children: <Widget>[
                                     Icon(Icons.search, color: Colors.blueAccent,),
                                     SizedBox(width: 10,),
                                     Text('Search Destination'),
                                   ],
                                 ),
                               ),

                             ),
                           ),
                         ),
                       ),


                       SizedBox(height: 22,),

                       Row(
                         children: <Widget>[
                           Icon(Icons.home, color: BrandColors.colorDimText,),
                           SizedBox(width: 12,),
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: <Widget>[
                               Text('Home'),
                               SizedBox(height: 3,),
                               Text('Your residential address',
                                 style: TextStyle(fontSize: 11,
                                   color: BrandColors.colorDimText,),
                               )
                             ],
                           )
                         ],
                       ),

                       SizedBox(height: 10,),

                       BrandDivider(),

                       SizedBox(height: 16,),

                       Row(
                         children: <Widget>[
                           Icon(Icons.work_outline, color: BrandColors
                               .colorDimText,),
                           SizedBox(width: 12,),
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: <Widget>[
                               Text('Add Work'),
                               SizedBox(height: 3,),
                               Text('Your office address',
                                 style: TextStyle(fontSize: 11,
                                   color: BrandColors.colorDimText,),
                               )
                             ],
                           )
                         ],
                       ),

                     ],
                   ),
                 ),
               ),
             ),
           ),
               Positioned(
               left: 0,
               right: 0,
               bottom: 0,
                child: AnimatedSize(
                  vsync: this,
                 duration: new Duration(milliseconds: 150),
                  curve: Curves.easeIn,
                child: Container(

                decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                boxShadow: [
                BoxShadow(
                color: Colors.black26,
                blurRadius: 15.0, // soften the shadow
                spreadRadius: 0.5, //extend the shadow
                offset: Offset(
                0.7, // Move to right 10  horizontally
                0.7, // Move to bottom 10 Vertically
     ),
     )
     ],
     ),
                    height: ridedetailsheetheight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical:15),
                        child: Column(
                          children: <Widget>[


                             Container(
                              width:double.infinity,
                              color:Colors.white,
                                child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Row(

                                    children: [
                                        Image.asset('images/trucklogo.jpg',height:100,width:80,),
                                          SizedBox(width:30,),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                            Text('DeliveryTruck', style:TextStyle(fontSize:18,),),
                                            Text(((tripDirectionDetails != null )? tripDirectionDetails?.distanceText : '').toString(), style:TextStyle(fontSize:16,fontFamily: 'Brand-Bold'),),

                                                          ]
                                              ),
                                          SizedBox(width:50,),

                                          Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text((tripDirectionDetails != null )?   '\ Rs${HelperMethods.estimateFares(tripDirectionDetails!)}' : '', style:TextStyle(fontSize:16,fontFamily: 'Brand-Bold'),),

                                          ]
                                      ),


           ] ,
     ),
                     ),
                   ),

                             SizedBox(height:22,),

                          Padding(
                             padding: EdgeInsets.symmetric(horizontal: 16),
                           child: Row(
                            children:<Widget>[
                             Icon(Icons.money,size:18,color:BrandColors.colorTextLight),
                             SizedBox(width:16,),
                             Text('cash'),
                             SizedBox(width:5,),
                             Icon(Icons.keyboard_arrow_down,size:16,color:BrandColors.colorTextLight),
                              ]
                            ) ,
                        ),
                            SizedBox(height:22,),
                            ElevatedButton.icon(
                              label: Text('Book the Order Delivery',),
                              icon: Icon(Icons.check_box),
                              onPressed: () {
                                showRequestingSheet();
                              },
                            )
                     ]
                      ),
                    )


       ),
                ),
     ), //Rider sheet

           Positioned(
             left: 0,
             right: 0,
             bottom: 0,
             child: AnimatedSize(
               vsync: this,
               duration: new Duration(milliseconds: 150),
               curve: Curves.easeIn,
               child: Container(
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black26,
                       blurRadius: 15.0, // soften the shadow
                       spreadRadius: 0.5, //extend the shadow
                       offset: Offset(
                         0.7, // Move to right 10  horizontally
                         0.7, // Move to bottom 10 Vertically
                       ),
                     )
                   ],
                 ),
                 height: requestingsheetHeight,
                 child: Padding(
                   padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.center,
                     children: <Widget>[

                       SizedBox(height: 10,),

                       SizedBox(
                         width: double.infinity,
                         child: TextLiquidFill(
                           text: 'Confirming Your Order ...',
                           waveColor: BrandColors.colorTextSemiLight,
                           boxBackgroundColor: Colors.white,
                           textStyle: TextStyle(
                               color: BrandColors.colorText,
                               fontSize: 22.0,
                               fontFamily: 'Brand-Bold'
                           ),
                           boxHeight: 40.0,
                         ),
                       ),

                       SizedBox(height: 20,),

                       GestureDetector(
                         onTap: (){
                           cancelRequest();
                           resetApp();
                         },
                         child: Container(
                           height: 50,
                           width: 50,
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(25),
                             border: Border.all(width: 1.0, color: BrandColors.colorLightGrayFair),

                           ),
                           child: Icon(Icons.close, size: 25,),
                         ),
                       ),

                       SizedBox(height: 10,),

                       Container(
                         width: double.infinity,
                         child: Text(
                           'Cancel ride',
                           textAlign: TextAlign.center,
                           style: TextStyle(fontSize: 12),
                         ),
                       ),


                     ],
                   ),
                 ),
               ),
             ),
           ),










     ],
     ),


     );


   }



   Future<void> getDirection() async {
     var pickup;
     var destination;
     pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
     destination = Provider.of<AppData>(context, listen: false).destinationAddress;

     var pickLatLng = LatLng(pickup.latitude, pickup.longitude);
     var destinationLatLng = LatLng(destination.latitude, destination.longitude);

         showDialog(
         barrierDismissible: false,
         context: context,
         builder: (BuildContext context) => ProgressDialog(status: 'Please wait...',)
     );
     var thisDetails;
     thisDetails= await HelperMethods.getDirectionDetails(pickLatLng, destinationLatLng);
     setState(() {
       tripDirectionDetails = thisDetails;
     });

     Navigator.pop(context);

     PolylinePoints polylinePoints = PolylinePoints();
     List<PointLatLng> results = polylinePoints.decodePolyline(thisDetails.encodedPoints);
       polylineCoordinates.clear();
       if (results.isNotEmpty) {
           results.forEach((PointLatLng point) {
           polylineCoordinates.add(LatLng(point.latitude, point.longitude));
         });
       }

       _polylines.clear();

       setState(() {
         Polyline polyline = Polyline(
           polylineId: PolylineId('polyid'),
           color: Color.fromARGB(255, 95, 109, 237),
           points: polylineCoordinates,
           jointType: JointType.round,
           width: 4,
           startCap: Cap.roundCap,
           endCap: Cap.roundCap,
           geodesic: true,
         );

         _polylines.add(polyline);
       });

     LatLngBounds bounds;

     if(pickLatLng.latitude > destinationLatLng.latitude && pickLatLng.longitude > destinationLatLng.longitude){
       bounds = LatLngBounds(southwest: destinationLatLng, northeast: pickLatLng);
     }
     else if(pickLatLng.longitude > destinationLatLng.longitude){
       bounds = LatLngBounds(
           southwest: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
           northeast: LatLng(destinationLatLng.latitude, pickLatLng.longitude)
       );
     }
     else if(pickLatLng.latitude > destinationLatLng.latitude){
       bounds = LatLngBounds(
         southwest: LatLng(destinationLatLng.latitude, pickLatLng.longitude),
         northeast: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
       );
     }
     else{
       bounds = LatLngBounds(southwest: pickLatLng, northeast: destinationLatLng);
     }
     mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));

     Marker pickupMarker = Marker(
       markerId: MarkerId('pickup'),
       position: pickLatLng,
       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
       infoWindow: InfoWindow(title: pickup.placeName, snippet: 'My Location'),
     );

     Marker destinationMarker = Marker(
       markerId: MarkerId('destination'),
       position: destinationLatLng,
       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
       infoWindow: InfoWindow(title: destination.placeName, snippet: 'Destination'),
     );

     setState(() {
       _Markers.add(pickupMarker);
       _Markers.add(destinationMarker);
     });

     Circle pickupCircle = Circle(
       circleId: CircleId('pickup'),
       strokeColor: Colors.green,
       strokeWidth: 3,
       radius: 12,
       center: pickLatLng,
       fillColor: BrandColors.colorGreen,
     );

     Circle destinationCircle = Circle(
       circleId: CircleId('destination'),
       strokeColor: BrandColors.colorAccentPurple,
       strokeWidth: 3,
       radius: 12,
       center: destinationLatLng,
       fillColor: BrandColors.colorAccentPurple,
     );



     setState(() {
       _Circles.add(pickupCircle);
       _Circles.add(destinationCircle);
     });


   }
   void cancelRequest(){
     resetApp();
     rideRef?.remove();
   }
   resetApp(){

     setState(() {
       polylineCoordinates.clear();
       _polylines.clear();
       _Markers.clear();
       _Circles.clear();
       searchsheetheight = 300;
       ridedetailsheetheight=0;
       requestingsheetHeight=0;
       mapBottomPadding = 260;
       drawerCanOpen = true;


     });

   void createRideRequest() {
     rideRef =
         FirebaseDatabase.instance.reference().child('rideRequest').push();

     var pickup = Provider
         .of<AppData>(context, listen: false)
         .pickupAddress;
     var destination = Provider
         .of<AppData>(context, listen: false)
         .destinationAddress;

     Map pickupMap = {
       'latitude': pickup?.latitude.toString(),
       'longitude': pickup?.longitude.toString(),
     };

     Map destinationMap = {
       'latitude': destination.latitude.toString(),
       'longitude': destination.longitude.toString(),
     };

     Map rideMap = {
       'created_at': DateTime.now().toString(),
       'rider_name': CurrentUserInfo?.email,
       'rider_email': CurrentUserInfo?.email,
       'pickup_address': pickup?.placeName,
       'destination_address': destination.placeName,
       'location': pickupMap,
       'destination': destinationMap,
       'payment_method': 'card',
       'driver_id': 'waiting',
     };
   }

  setupPostionlocator();
 }
}