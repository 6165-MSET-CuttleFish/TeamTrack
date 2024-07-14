import { useState, useEffect } from 'react';
import { Team, TeamListType } from '../types';
import { getTeamList } from '../api/api';

const useGetTeamList = (eventId: string): {
  teamList: TeamListType;
  loading: boolean;
  error: Error | null;
} => {
  const [teamList, setTeamList] = useState<TeamListType>({
    teams: [],
    isLoading: true,
    error: null,
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetchTeamList = async () => {
      setLoading(true);
      try {
        const response = await getTeamList(eventId);
        setTeamList({
          teams: response.teams,
          isLoading: false,
          error: null,
        });
      } catch (error) {
        setError(error as Error);
      } finally {
        setLoading(false);
      }
    };
    fetchTeamList();
  }, [eventId]);

  return { teamList, loading, error };
};

export default useGetTeamList;