import { useQuery } from "@tanstack/react-query";
import { getMatchList } from "../api/api";
import { MatchList } from "../api/api.types";

export const useGetMatchList = (eventId: string) => {
  return useQuery<MatchList[]>(["matchList", eventId], () => getMatchList(eventId));
};