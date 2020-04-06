import 'package:firebase_auth/firebase_auth.dart';

import '../LoginSystem.dart';
import 'package:Repository/Repository.dart';


typedef UserBuildCallback<T> = T Function(Map data);

class UserDataRepository<T extends UserModel> extends DatabaseRepository<T> {
  UserDataRepository(String path, this.userBuilder, [String uid = ""])
      : super(path,
            enableSync: true, useSubPath: true, autoInit: true, subPath: uid);
  final userBuilder;

  @override
  T mapToModel(Map dbData) {
    return userBuilder(dbData);
  }
}
