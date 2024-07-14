import { useQuery } from '@tanstack/react-query';
import { getMatch } from '../services/firebase/firebase';
import { Match } from '../models/Match';

export const useGetMatch = (id: string): { data: Match | undefined; isLoading: boolean; error: unknown | null } => {
  const { data, isLoading, error } = useQuery(['getMatch', id], () => getMatch(id));
  return { data, isLoading, error };
};