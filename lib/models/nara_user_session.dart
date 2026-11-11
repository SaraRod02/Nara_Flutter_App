
import 'package:flutter/foundation.dart';
import 'nara_user.dart';

class NaraUserSession {
  static final ValueNotifier<NaraUser?> currentUser =
      ValueNotifier<NaraUser?>(null);

  static void setUser(NaraUser user) {
    currentUser.value = user;
  }

  static void updateUser(NaraUser user) {
    currentUser.value = user;
  }

  static void clear() {
    currentUser.value = null;
  }
}
