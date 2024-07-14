import { Team } from '../../api/api.types';
import { StatConfig } from '../../api/api.types';
import { OpModeType } from '../../api/api.types';
import { ScoringElement } from '../../api/api.types';
import { Statistics } from '../../api/api.types';
import { Event } from '../../api/api.types';

export interface TeamListScreenProps {
  event: Event;
  sortMode: OpModeType | null;
  elementSort: ScoringElement | null;
  statConfig: StatConfig;
  statistic: Statistics;
}

export interface TeamListScreenData {
  teams: Team[];
  max: number;
}