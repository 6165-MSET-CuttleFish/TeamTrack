import { useMutation } from 'react-query';
import { createEvent } from '../services/firebase/firebase';
import { Event } from '../models/Event';

const useCreateEvent = () => {
  return useMutation<Event, Error, Event>({
    mutationFn: createEvent,
    onSuccess: (event) => {
      console.log('Event created successfully: ', event);
    },
    onError: (error) => {
      console.error('Error creating event: ', error);
    },
  });
};

export default useCreateEvent;