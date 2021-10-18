import 'package:teamtrack/models/AppModel.dart';

extension RoleExtension on Role {
  String name() { // getter for showing to the user
    switch (this) {
      case Role.viewer:
        return 'Viewer';
      case Role.editor:
        return 'Editor';
      case Role.admin:
        return 'Admin';
    }
  }

  String toRep() { // for firebase
    switch (this) {
      case Role.viewer:
        return 'viewer';
      case Role.editor:
        return 'editor';
      case Role.admin:
        return 'admin';
    }
  }
}