import { useMutation } from '@tanstack/react-query';
import { createTeam } from '../services/firebase/firebase';

const useCreateTeam = () => {
  const mutation = useMutation(createTeam, {
    onSuccess: () => {
      // TODO: Handle success
    },
    onError: (error) => {
      // TODO: Handle error
    },
  });

  return {
    createTeam: mutation.mutate,
    isLoading: mutation.isLoading,
    isError: mutation.isError,
    error: mutation.error,
  };
};

export default useCreateTeam;