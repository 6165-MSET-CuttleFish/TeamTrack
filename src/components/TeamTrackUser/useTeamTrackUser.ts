typescript
import { useState, useEffect, useContext } from "react";
import {
  Role,
  getRoleFromString,
  TeamTrackUser,
} from "../../models/AppModel";
import { useFirebaseAuth } from "../../providers/FirebaseAuth";
import {
  getDoc,
  doc,
  updateDoc,
  collection,
  onSnapshot,
  Firestore,
  DocumentData,
} from "firebase/firestore";
import { useFirestore } from "../../providers/Firestore";
import { useDataModel } from "../../providers/DataModel";

export default function useTeamTrackUser() {
  const [teamTrackUser, setTeamTrackUser] = useState<TeamTrackUser | null>(
    null
  );
  const { user, updateProfile } = useFirebaseAuth();
  const firestore = useFirestore();
  const dataModel = useDataModel();

  useEffect(() => {
    if (!user) return;
    const unsub = onSnapshot(
      doc(firestore, "users", user.uid),
      (snapshot) => {
        const data = snapshot.data() as DocumentData;
        const teamTrackUser = new TeamTrackUser.fromJson(
          data,
          user.uid,
          user.displayName,
          user.email,
          user.photoURL
        );
        setTeamTrackUser(teamTrackUser);
      }
    );
    return () => unsub();
  }, [user, firestore]);

  const updateRole = async (newRole: Role) => {
    if (!user) return;
    await updateDoc(doc(firestore, "users", user.uid), { role: newRole });
    const updatedTeamTrackUser = new TeamTrackUser.fromJson(
      {
        ...teamTrackUser,
        role: newRole,
      },
      user.uid,
      user.displayName,
      user.email,
      user.photoURL
    );
    setTeamTrackUser(updatedTeamTrackUser);
  };

  const updateDisplayName = async (displayName: string) => {
    if (!user) return;
    updateProfile({ displayName: displayName });
    const updatedTeamTrackUser = new TeamTrackUser.fromJson(
      {
        ...teamTrackUser,
        displayName: displayName,
      },
      user.uid,
      user.displayName,
      user.email,
      user.photoURL
    );
    setTeamTrackUser(updatedTeamTrackUser);
  };

  const updateWatchingTeam = async (teamNumber: string) => {
    if (!user) return;
    await updateDoc(doc(firestore, "users", user.uid), {
      watchingTeam: teamNumber,
    });
    const updatedTeamTrackUser = new TeamTrackUser.fromJson(
      {
        ...teamTrackUser,
        watchingTeam: teamNumber,
      },
      user.uid,
      user.displayName,
      user.email,
      user.photoURL
    );
    setTeamTrackUser(updatedTeamTrackUser);
  };

  return {
    teamTrackUser,
    updateRole,
    updateDisplayName,
    updateWatchingTeam,
  };
}