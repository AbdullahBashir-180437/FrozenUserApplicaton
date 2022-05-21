import 'dart:convert';

import 'package:http/http.dart' as http;
class Requesthelper{

  static Future<dynamic> getRequest(String url) async{

    http.Response response=await http.get(Uri.parse(url));
    try{
      if(response.statusCode == 200){
        String data =response.body;
        var decodeddata = jsonDecode(data);
        return decodeddata;
      }
      else{
        return 'failed';
      }
    }
    catch(e){
      return 'failed';
    }


  }
}