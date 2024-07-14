import { useQuery } from '@tanstack/react-query';
import { getTeam } from '../api/api';

export const useGetTeam = (teamId: string) => {
  return useQuery(['getTeam', teamId], () => getTeam(teamId), {
    enabled: !!teamId,
    refetchOnWindowFocus: false,
    retry: false,
  });
};