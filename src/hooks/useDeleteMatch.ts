import { useMutation } from '@tanstack/react-query';
import { deleteMatch } from '../services/firebase/firebase';
import { useGetMatchList } from './useGetMatchList';

export const useDeleteMatch = () => {
  const { refetch } = useGetMatchList();
  const { mutate: deleteMatchMutation } = useMutation({
    mutationFn: (matchId: string) => deleteMatch(matchId),
    onSuccess: () => {
      refetch();
    },
    onError: (error: any) => {
      console.error(error);
    },
  });

  return {
    deleteMatch: deleteMatchMutation,
  };
};