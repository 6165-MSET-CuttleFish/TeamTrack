typescript
import { Team, Event, OpModeType, ScoringElement } from '../../models';
import { Statistics } from '../../functions';

export interface TeamCardProps {
  team: Team;
  event: Event;
  max: number;
  sortMode?: OpModeType;
  elementSort?: ScoringElement;
  statistics: Statistics;
  onTap?: () => void;
}

export type TeamCardState = {
  percentIncrease?: number;
  wlt?: string[];
  teamStats?: {
    x: number;
    y: number;
  }[];
};