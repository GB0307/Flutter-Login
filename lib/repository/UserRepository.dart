import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseUserRepository {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser _user;

  FirebaseUser get currentUser => _user;

  StreamSubscription<FirebaseUser> authListener;

  FirebaseUserRepository(){
    authListener = _auth.onAuthStateChanged.listen((user) {
      if(currentUser == null && user != null){
        // user logged in
      }
      else if(currentUser != null && user == null){
        //user logged out
      }
      else if(currentUser != null && user != null && currentUser.uid != user.uid){
        // the user has changed
      }
      //else, user is the same
    });
  } 

}
