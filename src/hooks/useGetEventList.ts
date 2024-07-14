import { useState, useEffect } from 'react';
import { useFirebase } from '../useFirebaseAuth';
import { Event } from '../../models/Event';
import { EventType } from '../../models/EventType';

export const useGetEventList = () => {
  const [events, setEvents] = useState<Event[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const firebase = useFirebase();

  useEffect(() => {
    const unsubscribe = firebase.events().onSnapshot((snapshot) => {
      const eventData = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          name: data.name,
          type: data.type as EventType,
          gameName: data.gameName,
          createdAt: data.createdAt.toDate(),
          shared: data.shared,
          matches: data.matches.map((match) => ({
            id: match.id,
            team1: match.team1,
            team2: match.team2,
            scoreTeam1: match.scoreTeam1,
            scoreTeam2: match.scoreTeam2,
            winner: match.winner,
            createdAt: match.createdAt.toDate(),
          })),
          teams: data.teams.map((team) => ({
            id: team.id,
            name: team.name,
            players: team.players,
            wins: team.wins,
            losses: team.losses,
          })),
        };
      });
      setEvents(eventData);
      setIsLoading(false);
    });

    return () => {
      unsubscribe();
    };
  }, []);

  return { events, isLoading };
};