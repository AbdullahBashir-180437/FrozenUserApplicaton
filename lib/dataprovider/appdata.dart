import 'package:flutter/cupertino.dart';

import '../datamodels/address.dart';

class AppData extends ChangeNotifier{

  Address? pickupAddress;

  late Address destinationAddress;

  void updatePickupAddress(Address pickup){
    pickupAddress = pickup;
    notifyListeners();
  }

  void updateDestinationAddress (Address destination){
    destinationAddress = destination;
    notifyListeners();
  }
}