import { useMutation, useQueryClient } from 'react-query';
import { Match, UpdateMatchData } from '../models/Match';
import { firebaseUpdateMatch } from '../services/firebase/firebase';

export const useUpdateMatch = () => {
  const queryClient = useQueryClient();
  return useMutation<Match, Error, UpdateMatchData>(
    (updateMatchData: UpdateMatchData) =>
      firebaseUpdateMatch(updateMatchData),
    {
      onSuccess: (updatedMatch: Match) => {
        queryClient.invalidateQueries(['matches']);
        queryClient.invalidateQueries(['match', updatedMatch.id]);
      },
    },
  );
};