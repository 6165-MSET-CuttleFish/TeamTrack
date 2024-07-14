export enum EventType {
  Local = 'local',
  Remote = 'remote',
  Analysis = 'analysis',
}

export enum Role {
  Admin = 'admin',
  Editor = 'editor',
  Viewer = 'viewer',
}

export enum OpModeType {
  Auto = 'auto',
  Tele = 'tele',
  Endgame = 'endgame',
  Penalty = 'penalty',
}

export enum Dice {
  One = 'one',
  Two = 'two',
  Three = 'three',
  None = 'none',
}

export type MatchType = 'red' | 'blue';
export type ScoreType = 'team' | 'alliance';