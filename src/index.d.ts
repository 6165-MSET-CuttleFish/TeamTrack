typescript
import { Timestamp } from 'firebase/firestore';
import { HttpsCallableResult } from 'firebase/functions';
import { User } from 'firebase/auth';
import { DatabaseReference } from 'firebase/database';

export enum Role {
  admin = 'admin',
  editor = 'editor',
  viewer = 'viewer',
}

export interface TeamTrackUser {
  role: Role;
  email?: string;
  displayName?: string;
  photoURL?: string;
  watchingTeam?: string;
  uid?: string;
}

export interface DataModel {
  events: Event[];
  sharedEvents: Event[];
  token?: string;
  inbox: Event[];
  blockedUsers: TeamTrackUser[];
  allEvents(): Event[];
  localEvents(): Event[];
  remoteEvents(): Event[];
  driverAnalysis(): Event[];
  saveEvents(): Promise<void>;
  restoreEvents(): Promise<void>;
}

export enum EventType {
  local = 'local',
  remote = 'remote',
  analysis = 'analysis',
}

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

export interface Statics {
  gameName: string;
}

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
  teams: { [key: string]: Team };
  userTeam: Team;
  alliances: Team[][];
  rankedTeams: any[];
  currentTurn: number;
  currentPartner: number;
  matches: { [key: string]: Match };
  name: string;
  createdAt: Timestamp;
  sendTime?: Timestamp;
  sender?: TeamTrackUser;
  users: TeamTrackUser[];
  getKey(): string | undefined;
  hasKey(): boolean;
  addTeam(newTeam: Team): Promise<void>;
  updateUserTeam(newTeam: Team): Promise<void>;
  dontShow(): Promise<void>;
  checkDontShow(team: Team): void;
  setCurrentTurn(x: number): Promise<void>;
  setCurrentPartner(x: number): Promise<void>;
  addAllianceTeam(newTeam: Team, allianceIndex: number, rankNum: number): Promise<void>;
  createRankedList(teams: Team[]): Promise<void>;
  removeFromRankedList(team: Team): Promise<void>;
  getSortedMatches(ascending: boolean): Match[];
  getAllTeams(): Team[];
  getAllMatches(T: any): Match[];
  getTTUserFromUser(user: User | null): TeamTrackUser;
  getMatches(team: Team): Match[];
  addChange(change: Change, team: Team): Promise<void>;
  deleteChange(change: Change, team: Team): Promise<void>;
  modifyUser(params: { uid?: string; role?: Role }): Promise<HttpsCallableResult<any>>;
  addMatch(e: Match): Promise<void>;
  deleteTeam(team: Team): string | undefined;
  deleteMatch(e: Match): void;
  updateLocal(map: any, context: any): void;
  getRef(): DatabaseReference | null;
  fromJson(json: any): void;
  toJson(cloudFirestore?: boolean): {
    gameName: string;
    name: string;
    teams: { [key: string]: any };
    matches: { [key: string]: any };
    type: string;
    shared: boolean;
    id: string;
    author: any;
    seconds: number;
    nanoSeconds: number;
    createdAt: Timestamp | any;
    event_key?: string;
  };
  toSimpleJson(): {
    gameName: string;
    name: string;
    type: string;
    sendTime?: Timestamp;
    id: string;
  };
  shareEvent(params: { email: string; role: Role }): Promise<HttpsCallableResult<any>>;
}

export interface StatConfig {
  allianceTotal: boolean;
}

export interface Change {
  id: string;
  startDate: Date;
  endDate: Date;
  toJson(): { id: string; startDate: Date; endDate: Date };
}

export interface Alliance {
  team1?: Team;
  team2?: Team;
  eventType: EventType;
  opposingAlliance?: Alliance;
  sharedScore: Score;
  id?: string;
  totalScore?: number;
  gameName: string;
  teams: Set<Team | undefined>;
  getPenalty(): number;
  hasTeam(team: Team): boolean;
  penaltyTotal(): number;
  combinedScore(): Score;
  allianceTotal(showPenalties?: boolean, params?: { type?: OpModeType; element?: ScoringElement }): number;
  fromJson(json: { team1?: string; team2?: string; sharedScore: any }, teamList: { [key: string]: Team }, eventType: EventType, gameName: string): void;
  toJson(): {
    team1?: string;
    team2?: string;
    sharedScore: any;
  };
}

export interface Match {
  type: EventType;
  dice: Dice;
  red?: Alliance;
  blue?: Alliance;
  id: string;
  activeUsers?: TeamTrackUser[];
  timeStamp: Timestamp;
  alliance(team: Team | null): Alliance | null;
  opposingAlliance(team: Team | null): Alliance | null;
  getTeams(): (Team | null)[];
  getAlliances(): (Alliance | null)[];
  setDice(dice: Dice): void;
  score(params: { showPenalties?: boolean }): string;
  setAPIScore(redScore: number, blueScore: number): void;
  getRedAPI(): number | undefined;
  getBlueAPI(): number | undefined;
  getMaxScoreVal(params: { showPenalties?: boolean }): number;
  redScore(params: { showPenalties?: boolean }): number;
  blueScore(params: { showPenalties?: boolean }): number;
  getWinner(): Alliance | null;
  fromJson(json: any, teamList: { [key: string]: Team }, type: EventType, gameName: string): void;
  toJson(): {
    red: any;
    blue: any;
    dice: string;
    id: string;
    createdAt: any;
  };
  getScore(number: string | null): Score | null;
  getAllianceScore(number: string): Score | null;
}

export interface Team {
  name: string;
  number: string;
  established?: number;
  city?: string;
  scores: { [key: string]: Score };
  changes: Change[];
  targetScore?: Score;
  isRecommended?: boolean;
  deleteChange(change: Change): void;
  addChange(change: Change): void;
  getWLT(event: Event): string | null;
  getTotalScore(event: Event): number;
  getAllianceScore(event: Event): number;
  getSpecificScore(event: Event, opModeType: OpModeType): number;
  fromJson(json: any, gameName: string): void;
  updateWithTOA(toa: any): void;
  toJson(): {
    name: string;
    number: string;
    scores: { [key: string]: any };
    targetScore?: any;
    changes: { [key: string]: any };
  };
}

export interface Score {
  id: string;
  dice: Dice;
  gameName: string;
  isAllianceScore?: boolean;
  penalties: Penalties;
  getScoreDivision(type?: OpModeType): ScoreDivision;
  getScoringElementCount(key?: string): number;
  toJson(): {
    id: string;
    dice: string;
    penalties: any;
    scoringElements: { [key: string]: number };
    isAllianceScore: boolean;
  };
  fromJson(json: any, gameName: string, isAllianceScore?: boolean): void;
  setDice(dice: Dice, timeStamp: Timestamp): void;
  addScore(score: Score): void;
}

export interface Penalties {
  major: number;
  minor: number;
  total(): number;
}

export interface ScoreDivision {
  scoringElements: { [key: string]: number };
  getScoringElementCount(key?: string): number;
}

export interface ScoringElement {
  key: string;
  value: number;
}

export const dataModel: DataModel;
export const themeChangeProvider: any;
export const firebaseDatabase: DatabaseReference;
export const functions: any;
export const firebaseFirestore: any;
export const messaging: any;
export const firebaseAuth: any;
export const remoteConfig: any;