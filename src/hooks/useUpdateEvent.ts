import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Event, UpdateEventInput } from "../api/api.types";
import { updateEvent } from "../api/api";

export const useUpdateEvent = () => {
  const queryClient = useQueryClient();

  return useMutation<Event, Error, UpdateEventInput>(
    (updateEventInput: UpdateEventInput) => updateEvent(updateEventInput),
    {
      onSuccess: (data) => {
        queryClient.invalidateQueries(["events"]);
        queryClient.invalidateQueries(["event", data.id]);
      },
    }
  );
};