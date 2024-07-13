typescript
import { Timestamp } from 'firebase/firestore';
import { RemoteConfig } from 'firebase/remote-config';

// Represents the type of event being played
export enum EventType {
  local = 'local',
  remote = 'remote',
  analysis = 'analysis',
}

// Represents the random dice roll for the autonomous period (which can sometimes inform other periods) and so is useful to track
export enum Dice {
  one = 'one',
  two = 'two',
  three = 'three',
  none = 'none',
}

export enum OpModeType {
  auto = 'auto',
  tele = 'tele',
  endgame = 'endgame',
  penalty = 'penalty',
}

export enum Role {
  editor = 'editor',
  viewer = 'viewer',
  admin = 'admin',
}

export interface TeamTrackUser {
  displayName?: string;
  email?: string;
  photoURL?: string;
  role: Role;
  uid?: string;
}

export interface StatConfig {
  allianceTotal: boolean;
}

// Represents a single scoring element in a Score
export interface ScoringElement {
  key: string;
  value: number;
}

// Represents a single score for a match
export interface Score {
  id: string;
  dice: Dice;
  gameName: string;
  isAllianceScore?: boolean;
  penalties: Penalty;
  scoringElements: Map<string, ScoringElement>;
  // TODO: potentially include a Timestamp here, to record the time of the score
  // but this would require changes to the database
}

export interface Penalty {
  total: () => number;
}

// Represents the score for a single team in a match
export class TeamScore implements Score {
  id: string;
  dice: Dice;
  gameName: string;
  isAllianceScore: boolean;
  penalties: Penalty;
  scoringElements: Map<string, ScoringElement>;

  constructor(id: string, dice: Dice, gameName: string, isAllianceScore?: boolean) {
    this.id = id;
    this.dice = dice;
    this.gameName = gameName;
    this.isAllianceScore = isAllianceScore ?? false;
    this.penalties = new Penalty();
    this.scoringElements = new Map();
  }

  addScoringElement(scoringElement: ScoringElement): void {
    this.scoringElements.set(scoringElement.key, scoringElement);
  }

  getScoringElementCount(key?: string): number {
    if (key) {
      return this.scoringElements.get(key)?.value ?? 0;
    }
    return Object.values(this.scoringElements).reduce((a, b) => a + b.value, 0);
  }

  getScoreDivision(type?: OpModeType): TeamScore {
    // TODO: implement logic for getting score division based on type
    return this;
  }

  setDice(dice: Dice, timeStamp: Timestamp): void {
    this.dice = dice;
  }

  addPenalty(penalty: number): void {
    this.penalties.total = () => this.penalties.total() + penalty;
  }

  toJson(): any {
    return {
      id: this.id,
      dice: this.dice,
      gameName: this.gameName,
      isAllianceScore: this.isAllianceScore,
      penalties: {
        total: this.penalties.total(),
      },
      scoringElements: this.scoringElements,
    };
  }

  // TODO: implement equals() method
  // equals(other: Score): boolean {
  //   // ...
  // }

  // TODO: implement + operator
  // operator +(other: Score): Score {
  //   // ...
  // }
}

// Represents a single team
export class Team {
  name: string;
  number: string;
  established?: number;
  city?: string;
  scores: Map<string, TeamScore>;
  changes: Change[];
  targetScore?: Score;
  isRecommended?: boolean;

  constructor(number: string, name: string) {
    this.number = number;
    this.name = name;
    this.scores = new Map();
    this.changes = [];
  }

  addChange(change: Change): void {
    this.changes.push(change);
    this.changes.sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  deleteChange(change: Change): void {
    this.changes.splice(this.changes.indexOf(change), 1);
  }

  addScore(score: TeamScore): void {
    this.scores.set(score.id, score);
  }

  getScore(matchId: string): TeamScore | undefined {
    return this.scores.get(matchId);
  }

  toJson(): any {
    return {
      name: this.name,
      number: this.number,
      established: this.established,
      city: this.city,
      scores: this.scores,
      targetScore: this.targetScore?.toJson(),
      changes: this.changes,
    };
  }

  equals(other: Team): boolean {
    return this.number === other.number;
  }

  // TODO: implement updateWithTOA() method
  // updateWithTOA(toa: any): void {
  //   // ...
  // }
}

// Represents a single alliance
export class Alliance {
  team1?: Team;
  team2?: Team;
  eventType: EventType;
  opposingAlliance?: Alliance;
  sharedScore: TeamScore;
  id?: string;
  totalScore?: number;
  gameName: string;

  constructor(team1?: Team, team2?: Team, eventType: EventType, gameName: string) {
    this.team1 = team1;
    this.team2 = team2;
    this.eventType = eventType;
    this.gameName = gameName;
    this.sharedScore = new TeamScore(
      '',
      Dice.none,
      gameName,
      true,
    );
  }

  get teams(): Set<Team | undefined> {
    return new Set([this.team1, this.team2]);
  }

  getPenalty(): number {
    if (this.eventType === EventType.remote) {
      return this.team1?.scores[this.id]?.penalties.total() ?? 0;
    }

    const penaltiesAddToOpposingAlliance =
      JSON.parse(RemoteConfig.getInstance().getString(this.gameName))['PenaltiesAddToOpposingAlliance'] ?? false;

    if (penaltiesAddToOpposingAlliance) {
      return -(this.opposingAlliance?.penaltyTotal() ?? 0);
    } else {
      return this.penaltyTotal();
    }
  }

  hasTeam(team: Team): boolean {
    return this.teams.has(team);
  }

  penaltyTotal(): number {
    return [...this.teams]
      .map((team) => team?.scores[this.id]?.penalties.total() ?? 0)
      .reduce((a, b) => a + b, 0);
  }

  combinedScore(): TeamScore {
    return [...this.teams]
      .map((team) => team?.scores[this.id] ?? new TeamScore('', Dice.none, this.gameName))
      .reduce((a, b) => a + b) +
      this.sharedScore;
  }

  allianceTotal(showPenalties?: boolean, type?: OpModeType, element?: ScoringElement): number {
    return (
      [...this.teams]
        .map((e) => e?.scores[this.id]?.getScoreDivision(type)?.getScoringElementCount(element?.key) ?? 0)
        .reduce((a, b) => a + b, 0) +
      ((showPenalties ?? false) && type == null ? this.getPenalty() : 0) +
      (this.sharedScore.getScoreDivision(type)?.getScoringElementCount(element?.key) ?? 0)
    ).clamp(type == null ? 0 : -999, 999);
  }

  toJson(): any {
    return {
      team1: this.team1?.number,
      team2: this.team2?.number,
      sharedScore: this.sharedScore.toJson(),
    };
  }
}

// Represents a single match
export class Match {
  type: EventType;
  dice: Dice;
  red?: Alliance;
  blue?: Alliance;
  id: string;
  activeUsers?: TeamTrackUser[];
  timeStamp: Timestamp;

  constructor(red?: Alliance, blue?: Alliance, type: EventType) {
    this.red = red;
    this.blue = blue;
    this.type = type;
    this.id = '';
    this.timeStamp = Timestamp.now();
    this.red?.opposingAlliance = this.blue;
    this.blue?.opposingAlliance = this.red;
    this.red?.id = this.id;
    this.blue?.id = this.id;
    this.activeUsers = [];
  }

  static defaultMatch(type: EventType): Match {
    return new Match(
      new Alliance(new Team('1', 'Alpha'), new Team('2', 'Beta'), type, ''),
      new Alliance(new Team('3', 'Charlie'), new Team('4', 'Delta'), type, ''),
      type,
    );
  }

  alliance(team?: Team): Alliance | undefined {
    if (this.red?.team1?.equals(team) ?? false || this.red?.team2?.equals(team) ?? false) {
      return this.red;
    } else if (this.blue?.team1?.equals(team) ?? false || this.blue?.team2?.equals(team) ?? false) {
      return this.blue;
    }
    return undefined;
  }

  opposingAlliance(team?: Team): Alliance | undefined {
    if (this.red?.team1?.equals(team) ?? false || this.red?.team2?.equals(team) ?? false) {
      return this.blue;
    } else if (this.blue?.team1?.equals(team) ?? false || this.blue?.team2?.equals(team) ?? false) {
      return this.red;
    }
    return undefined;
  }

  getTeams(): (Team | undefined)[] {
    return [this.red?.team1, this.red?.team2, this.blue?.team1, this.blue?.team2];
  }

  getAlliances(): (Alliance | undefined)[] {
    return [this.red, this.blue];
  }

  setDice(dice: Dice): void {
    this.dice = dice;
    this.red?.team1?.scores[this.id]?.setDice(dice, this.timeStamp);
    this.red?.team2?.scores[this.id]?.setDice(dice, this.timeStamp);
    this.blue?.team1?.scores[this.id]?.setDice(dice, this.timeStamp);
    this.blue?.team2?.scores[this.id]?.setDice(dice, this.timeStamp);
  }

  score(showPenalties?: boolean): string {
    if (this.type === EventType.remote) {
      return this.redScore(showPenalties).toString();
    }
    return this.redScore(showPenalties).toString() + ' - ' + this.blueScore(showPenalties).toString();
  }

  setAPIScore(redScore: number, blueScore: number): void {
    this.red?.totalScore = redScore;
    this.blue?.totalScore = blueScore;
  }

  getRedAPI(): number | undefined {
    return this.red?.totalScore;
  }

  getBlueAPI(): number | undefined {
    return this.blue?.totalScore;
  }

  getMaxScoreVal(showPenalties?: boolean): number {
    return [this.redScore(showPenalties), this.blueScore(showPenalties)].reduce((a, b) => Math.max(a, b), 0);
  }

  redScore(showPenalties?: boolean): number {
    return this.red?.allianceTotal(showPenalties) ?? 0;
  }

  blueScore(showPenalties?: boolean): number {
    return this.blue?.allianceTotal(showPenalties) ?? 0;
  }

  getWinner(): Alliance | undefined {
    if (this.redScore(true) > this.blueScore(true)) {
      return this.red;
    } else if (this.redScore(true) < this.blueScore(true)) {
      return this.blue;
    } else {
      return undefined;
    }
  }

  toJson(): any {
    return {
      red: this.red?.toJson(),
      blue: this.blue?.toJson(),
      dice: this.dice,
      id: this.id,
      timeStamp: this.timeStamp.toDate(),
    };
  }

  getScore(number: string): TeamScore | undefined {
    if (number === this.red?.team1?.number) {
      return this.red?.team1?.scores[this.id];
    } else if (number === this.red?.team2?.number) {
      return this.red?.team2?.scores[this.id];
    } else if (number === this.blue?.team1?.number) {
      return this.blue?.team1?.scores[this.id];
    } else if (number === this.blue?.team2?.number) {
      return this.blue?.team2?.scores[this.id];
    }
    return undefined;
  }

  getAllianceScore(number: string): TeamScore | undefined {
    if (number === this.red?.team1?.number || number === this.red?.team2?.number) {
      return this.red?.combinedScore();
    } else if (number === this.blue?.team1?.number || number === this.blue?.team2?.number) {
      return this.blue?.combinedScore();
    }
    return undefined;
  }
}

// Represents a single change
export interface Change {
  id: string;
  startDate: Date;
  endDate?: Date;
  changeType: string;
  changeDetails: string;
}

export function getDiceFromString(diceString: string): Dice {
  switch (diceString) {
    case 'one':
      return Dice.one;
    case 'two':
      return Dice.two;
    case 'three':
      return Dice.three;
    default:
      return Dice.none;
  }
}

export function getTypeFromString(typeString: string): EventType {
  switch (typeString) {
    case 'local':
      return EventType.local;
    case 'remote':
      return EventType.remote;
    case 'analysis':
      return EventType.analysis;
    default:
      return EventType.local;
  }
}

export function getTimestampFromString(timestampString: string): Timestamp | null {
  if (timestampString) {
    return Timestamp.fromDate(new Date(timestampString));
  }
  return null;
}

// Represents a single event
export interface Event {
  eventKey?: string;
  id: string;
  statConfig: StatConfig;
  author?: TeamTrackUser;
  hide: boolean;
  gameName: string;
  role: Role;
  shared: boolean;
  type: EventType;
  teams: Map<string, Team>;
  userTeam: Team;
  alliances: Team[][];
  rankedTeams: Team[];
  currentTurn: number;
  currentPartner: number;
  matches: Map<string, Match>;
  name: string;
  createdAt: Timestamp;
  sendTime?: Timestamp;
  sender?: TeamTrackUser;
  users: TeamTrackUser[];
  // TODO: add other properties
}

export interface EventOptions {
  name: string;
  type: EventType;
  gameName: string;
  eventKey?: string;
  role?: Role;
}