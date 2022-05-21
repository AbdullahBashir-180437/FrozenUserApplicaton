import 'package:firebase_database/firebase_database.dart';

class Users {
 String? id;
 String? email;
 String? name;

 Users({this.id, this.email,  this.name});

 Users.fromSnapshot(DataSnapshot dataSnapshot) {
  id = dataSnapshot.key!;

  var data = dataSnapshot.value as Map?;

  if (data != null) {
   email = data["email"];
   name = data["name"];

  }
 }
}