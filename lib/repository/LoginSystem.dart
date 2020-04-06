import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../LoginSystem.dart';


// This class should implement main features for FirebaseAuth and link them with Firebase database
// The goal is to make it abstract, so we can reuse it

typedef InvalidHandler<T> = T Function(T user);
typedef AuthEvent<T extends UserModel> = void Function(T oldUser, T newUser);

class LoginSystem<T extends UserModel> {
  LoginSystem(String usersPath,
      {@required UserBuilder<T> userBuilder,
      String uid = "",
      InvalidHandler<T> onUserInvalid,
      this.onLogIn,
      this.onLogOut,
      this.onUserChanged,
      this.waitTimeout = const Duration(seconds: 3),
      this.loginTimeout = const Duration(seconds: 3)})
      : repository = new UserDataRepository(
          usersPath,
          userBuilder,
        ),
        _onUserInvalid = onUserInvalid;

  T _user;
  T get currentUser => _user;

  FirebaseUser _fbUser;
  FirebaseUser get fbUser => _fbUser;

  // Callbacks
  final InvalidHandler<T> _onUserInvalid;
  final AuthEvent<T> onLogIn;
  final AuthEvent<T> onLogOut;
  final AuthEvent<T> onUserChanged;

  // Repository Variables
  final UserDataRepository<T> repository;

  // Timeouts
  final Duration loginTimeout;
  final Duration waitTimeout;

  // Stream Variables
  @protected
  final StreamController<T> controller = new StreamController.broadcast();
  Stream<T> get stream => controller.stream;

  // Firebase Auth
  @protected
  FirebaseAuth auth = FirebaseAuth.instance;

  // Listeners
  StreamSubscription<FirebaseUser> authListener;
  StreamSubscription<T> repoListener;

  void init() {
    // Init the auth listener, so it can receive the current user
    if (authListener != null) {
      authListener.cancel();
    }
    authListener = auth.onAuthStateChanged.listen(onUserReceived);

    if (repoListener != null) {
      repoListener.cancel();
    }
    repoListener = repository.stream.listen((UserModel event) async {
      var model = await _buildModel(_fbUser, event, true);
      setUser(model);
    });
  }

  @protected
  void onUserReceived(FirebaseUser user) async {
    print("User Received: " + (user == null ? "null" : user.uid));

    //user logged in or changed
    if ((user != null && currentUser == null) ||
        (user != null && currentUser != null && user.uid == currentUser.uid)) {
      print("USER LOGGED IN");
      repository.changeSubPath(user.uid);
      var model = await _buildModel(user);

      _fbUser = user;
      setUser(model);
    }

    //user logged out
    if (_fbUser != null && user == null) {
      print("USER LOGGED OUT");
      repository.changeSubPath(null);

      _fbUser = user;
      setUser(null);
    }
  }

  Future<T> _buildModel(FirebaseUser user,
      [UserModel model, bool fetched = false]) async {
    // try to get the current model, else the first model in the stream, then, the current again
    if (!fetched)
      model = model ??
          repository.currentData ??
          await repository.stream.first.timeout(waitTimeout) ??
          repository.currentData;

    // set the user if the model isn't null
    if (model != null) model.setUser(user);

    // call invalid user handler if the data is invalid and there is a callback
    if (_onUserInvalid != null &&
        (model == null || !await model.validateData()))
      model = _onUserInvalid(model);

    return model;
  }

  void setUser(UserModel model) async {
    // check if it still invalid, if it is, log out
    T old = currentUser;
    if (model == null || !await model.validateData()) {
      if (_fbUser != null) auth.signOut();
      model = null;
      _user = null;
      controller.add(null);
    } else {
      _user = model;
      controller.add(_user);
    }

    // call callbacks
    _callbacks(old, _user);
  }

  Future<T> login(String email, String password) async {
    auth.signInWithEmailAndPassword(email: email, password: password);
    return stream.first.timeout(loginTimeout);
  }

  void _callbacks(T oldUser, T newUser) {
    /// Call callbacks based on the new and old users
    bool oldIsNull = oldUser == null;
    bool newIsNull = newUser == null;

    if (onLogIn != null && oldIsNull && !newIsNull)
      onLogIn(oldUser, newUser);
    else if (onLogOut != null && !oldIsNull && newIsNull)
      onLogOut(oldUser, newUser);
    else if (onUserChanged != null) onUserChanged(oldUser, newUser);
  }

  void _disableListeners() {
    /// Disable listeners when no user is logged
    print("DISABLING LISTENERS");
    if (authListener != null) {
      authListener.cancel();
      authListener = null;
    }

    if (repoListener != null) {
      repoListener.cancel();
      repoListener = null;
    }
  }

  void signOut() => auth.signOut();

  void dispose() {
    _disableListeners();
    repository.dispose();
    controller.close();
  }
}

//TODO: UPDATE USER DATA
//TODO: CREATE USER
