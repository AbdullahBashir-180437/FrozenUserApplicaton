import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../Global/global.dart';
import '../datamodels/address.dart';
import '../datamodels/directiondetails.dart';
import '../datamodels/user.dart';
import '../dataprovider/appdata.dart';
import '../globalvariable.dart';
import 'Requesthelper.dart';

class HelperMethods {


  static Future<String> findCordinateAddress(Position position, context) async {

    String placeAddress = '';

    var connectivityResult = await Connectivity().checkConnectivity();
    if(connectivityResult != ConnectivityResult.mobile && connectivityResult != ConnectivityResult.wifi){
      return placeAddress;
    }

    String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapkey';

    var response = await Requesthelper.getRequest(url);

    if(response != 'failed'){
      placeAddress = response['results'][0]['formatted_address'];

      Address pickupAddress = new Address();

      pickupAddress.longitude = position.longitude;
      pickupAddress.latitude = position.latitude;
      pickupAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false).updatePickupAddress(pickupAddress);

    }

    return placeAddress;

  }
  static Future<DirectionDetails?>getDirectionDetails(LatLng startPosition, LatLng endPosition) async {

    String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${startPosition.latitude},${startPosition.longitude}&destination=${endPosition.latitude},${endPosition.longitude}&mode=driving&key=$mapkey';

    var response = await Requesthelper.getRequest(url);

    if(response == 'failed'){
      return null;
    }

  DirectionDetails directionDetails = DirectionDetails();

    directionDetails.durationText = response['routes'][0]['legs'][0]['duration']['text'];
    directionDetails.durationValue = response['routes'][0]['legs'][0]['duration']['value'];

    directionDetails.distanceText = response['routes'][0]['legs'][0]['distance']['text'];
    directionDetails.distanceValue = response['routes'][0]['legs'][0]['distance']['value'];

    directionDetails.encodedPoints = response['routes'][0]['overview_polyline']['points'];

    return directionDetails;

  }
  static int estimateFares (DirectionDetails details){
    // per km = 94,
    // per minute = 15,
    // base fare = 500,

    double baseFare = 500;
    double distanceFare = (details.distanceValue!/1000) * 30;
    double timeFare = (details.durationValue! / 60) * 5;

    double totalFare = baseFare + distanceFare + timeFare;

    return totalFare.truncate();


  }

  static Future<void> getCurrentUserInfo() async {
    currentFirebaseUser = await FirebaseAuth.instance.currentUser;
    String userId = currentFirebaseUser!.uid;
    DatabaseReference reference =
    FirebaseDatabase.instance.ref().child("users").child(userId);

    final snapshot = await reference.get(); // you should use await on async methods
    if (snapshot.value != null) {
      Users CurrentUserInfo = Users.fromSnapshot(snapshot);
      print('mynameis ${CurrentUserInfo.name}');
    }
  }
}
