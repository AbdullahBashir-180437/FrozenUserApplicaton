import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../brand_colors.dart';
import '../datamodels/address.dart';
import '../datamodels/prediction.dart';
import '../dataprovider/appdata.dart';
import '../globalvariable.dart';
import '../helper/Requesthelper.dart';
import 'ProgressDialog.dart';

class PredictionTile extends StatelessWidget {

  final Prediction prediction;
  PredictionTile({required this.prediction});

  void getPlaceDetails(String placeID, context) async {

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => ProgressDialog(status: 'Please wait...',)
    );

    String url = 'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeID&key=$mapkey';

    var response = await Requesthelper.getRequest(url);

    Navigator.pop(context);

    if(response == 'failed'){
      return;
    }

    if(response['status'] == 'OK'){

      Address thisPlace = Address();
      thisPlace.placeName = response['result']['name'];
      thisPlace.placeId = placeID;
      thisPlace.latitude = response ['result']['geometry']['location']['lat'];
      thisPlace.longitude = response ['result']['geometry']['location']['lng'];

      Provider.of<AppData>(context, listen: false).updateDestinationAddress(thisPlace);
      print(thisPlace.placeName);



      Navigator.pop(context, 'getDirection');
    }

  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: (){
        getPlaceDetails(prediction.placeId.toString(), context);
      },
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Container(
          child: Column(
            children: <Widget>[
              SizedBox(height: 8,),
              Row(
                children: <Widget>[
                  Icon(Icons.location_on, color: BrandColors.colorDimText,),
                  SizedBox(width: 12,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(prediction.mainText.toString(),style: TextStyle(fontSize: 16),),
                        SizedBox(height: 2,),
                        Text(prediction.secondaryText.toString(), overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: BrandColors.colorDimText),),
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(height: 8,),

            ],
          ),
        ),
      ),
    );
  }
}