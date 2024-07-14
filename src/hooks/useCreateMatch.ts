import { useMutation } from '@tanstack/react-query';
import { Match } from '../../api/api.types';
import { createMatch } from '../../api/api';

export const useCreateMatch = () => {
  return useMutation<Match, Error, Match>({
    mutationFn: (match: Match) => createMatch(match),
  });
};