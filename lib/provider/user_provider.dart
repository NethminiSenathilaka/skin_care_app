import 'package:flutter/material.dart';

import '../models/spotelessyou_user.dart';

class UserProvider extends ChangeNotifier {
  SpotelessYouUser? _user;

  SpotelessYouUser? get user => _user;

  void setUser(SpotelessYouUser user) {
    _user = user;
    notifyListeners();
  }
}
