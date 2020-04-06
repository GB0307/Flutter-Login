import 'package:Repository/Repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class UserModel extends DBModel {
  String _uid;
  String get uid => _uid;

  FirebaseUser _fbUser;
  FirebaseUser get firebaseUser => _fbUser;

  UserModel.fromMap(String userPath, Map rawData)
      : super.fromMap(userPath, "", rawData);

  Future<bool> validateData();

  void setUser(FirebaseUser user) {
    if (user != null && _fbUser == null) {
      _fbUser = user;
      _uid = user.uid;
    }
  }
}
