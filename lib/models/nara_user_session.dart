
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nara_user.dart';

class NaraUserSession {
  static const String _userIdKey = 'nara_user_id';

  static final ValueNotifier<NaraUser?> currentUser =
      ValueNotifier<NaraUser?>(null);

  static Future<void> setUser(NaraUser user) async {
    currentUser.value = user;

    final preferences = await SharedPreferences.getInstance();

    if (user.idUsuario != null) {
      await preferences.setInt(_userIdKey, user.idUsuario!);
    }
  }

  static Future<void> updateUser(NaraUser user) async {
    await setUser(user);
  }

  static Future<void> clear() async {
    currentUser.value = null;

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_userIdKey);
  }

  static Future<int?> getSavedUserId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_userIdKey);
  }
}
