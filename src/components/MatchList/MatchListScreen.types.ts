import { Match } from '../../api/api.types';

export interface MatchListScreenProps {
  event: {
    id: string;
    name: string;
    matches: Match[];
    teams: {
      [key: number]: {
        id: string;
        number: number;
        name: string;
      }
    }
    statConfig: {
      allianceTotal: boolean;
      removeOutliers: boolean;
    }
  }
  team: {
    id: string;
    number: number;
    name: string;
  } | null;
  ascending: boolean;
}

export interface MatchListScreenState {
  fabIsVisible: boolean;
}