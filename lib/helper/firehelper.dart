import 'package:frozen2gouser/datamodels/nearbydrivers.dart';

class firehelper{
  static List<NearbyDriver> nearbydriverlist = [];

  static void removeFromlist(String key){
    int index = nearbydriverlist.indexWhere((element) => element.key == key);
    nearbydriverlist.removeAt(index);

  }

  static void updatenearbylocation(NearbyDriver driver){
    int index = nearbydriverlist.indexWhere((element) => element.key == driver.key);

    nearbydriverlist[index].longitude = driver.longitude;
    nearbydriverlist[index].longitude = driver.latitude;

  }
}
