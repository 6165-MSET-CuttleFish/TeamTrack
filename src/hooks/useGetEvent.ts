import { useQuery } from '@tanstack/react-query';
import { Event } from '../api/api.types';
import { getEvent } from '../api/api';

const useGetEvent = (eventId: string) => {
  const { data: event, isLoading, error } = useQuery<Event>({
    queryKey: ['event', eventId],
    queryFn: () => getEvent(eventId),
  });

  return { event, isLoading, error };
};

export default useGetEvent;