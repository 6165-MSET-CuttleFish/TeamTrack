import { useState, useEffect } from 'react';
import { useFirebaseAuth } from './useFirebaseAuth';
import { useGetTeam } from './useGetTeam';
import { UpdateTeamPayload } from '../api/api.types';
import { updateTeam } from '../api/api';

export const useUpdateTeam = (teamId: string) => {
  const { user } = useFirebaseAuth();
  const { team, isLoading, error } = useGetTeam(teamId);
  const [isUpdating, setIsUpdating] = useState(false);
  const [updateError, setUpdateError] = useState<string | null>(null);

  useEffect(() => {
    if (!team) {
      return;
    }

    const updateTeamData = async (payload: UpdateTeamPayload) => {
      setIsUpdating(true);
      setUpdateError(null);

      try {
        await updateTeam(payload);
      } catch (err: any) {
        setUpdateError(err.message);
      } finally {
        setIsUpdating(false);
      }
    };

    return () => {
      setIsUpdating(false);
      setUpdateError(null);
    };
  }, [team]);

  return {
    team,
    isLoading,
    error,
    isUpdating,
    updateError,
    updateTeam: updateTeamData,
  };
};