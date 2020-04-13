import 'package:flutter_repository/flutter_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class UserModel extends DBModel {
  String get uid => key;

  final FirebaseUser firebaseUser;

  UserModel.fromMap(String userPath, this.firebaseUser, Map rawData)
      : 
        super.fromMap(userPath, firebaseUser.uid, rawData);

  Future<bool> validateData();
}
