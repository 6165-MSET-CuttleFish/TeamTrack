typescript
import { Event, OpModeType, ScoringElement, StatConfig, Team, Statistics, Dice, Score } from "../../models";
import { percentIncrease } from "../../functions/Extensions";

interface TeamCardProps {
  team: Team;
  event: Event;
  max: number;
  sortMode?: OpModeType;
  onTap: () => void;
  statConfig: StatConfig;
  elementSort?: ScoringElement;
  statistics: Statistics;
}

interface TeamCardListProps {
  teams: Team[];
  event: Event;
  sortMode?: OpModeType;
  statConfig: StatConfig;
  elementSort?: ScoringElement;
  statistics: Statistics;
  isUserTeam?: boolean;
}

export type { TeamCardProps, TeamCardListProps };