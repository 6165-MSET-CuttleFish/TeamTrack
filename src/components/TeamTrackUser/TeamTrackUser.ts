typescript
import { Role } from '../models/AppModel';

export class TeamTrackUser {
  role: Role;
  email?: string;
  displayName?: string;
  photoURL?: string;
  watchingTeam?: string;
  uid?: string;

  constructor(
    role: Role,
    email?: string,
    displayName?: string,
    photoURL?: string,
    uid?: string,
    watchingTeam?: string
  ) {
    this.role = role;
    this.email = email;
    this.displayName = displayName;
    this.photoURL = photoURL;
    this.uid = uid;
    this.watchingTeam = watchingTeam;
  }

  static fromJson(json: any, uid: string): TeamTrackUser {
    return new TeamTrackUser(
      getRoleFromString(json['role']),
      json['email'],
      json['displayName'],
      json['photoURL'],
      uid,
      json['watchingTeam']
    );
  }

  static fromUser(user: any): TeamTrackUser {
    return new TeamTrackUser(
      Role.viewer,
      user?.email,
      user?.displayName,
      user?.photoURL,
      user?.uid
    );
  }

  toJson(teamNumber?: string): { [key: string]: string | undefined } {
    return {
      'role': this.role.toRep(),
      'email': this.email,
      'displayName': this.displayName,
      'photoURL': this.photoURL,
      'watchingTeam': teamNumber ?? this.watchingTeam,
    };
  }
}

const getRoleFromString = (role: string): Role => {
  switch (role) {
    case 'admin':
      return Role.admin;
    case 'editor':
      return Role.editor;
    case 'viewer':
      return Role.viewer;
    default:
      return Role.viewer;
  }
};

Role.prototype.toRep = function () {
  switch (this) {
    case Role.admin:
      return 'admin';
    case Role.editor:
      return 'editor';
    case Role.viewer:
      return 'viewer';
    default:
      return 'viewer';
  }
};