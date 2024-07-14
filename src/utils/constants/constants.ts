import { OpModeType, Dice } from '../../models/GameModel';

export const OpModeTypes = {
  [OpModeType.auto]: 'Autonomous',
  [OpModeType.tele]: 'Tele-Op',
  [OpModeType.endgame]: 'Endgame',
  [OpModeType.penalty]: 'Penalty',
};

export const DiceValues = {
  [Dice.one]: 'One',
  [Dice.two]: 'Two',
  [Dice.three]: 'Three',
};

export const RoleNames = {
  viewer: 'Viewer',
  editor: 'Editor',
  admin: 'Admin',
};

export const EventTypeNames = {
  local: 'In-Person Event',
  remote: 'Remote Event',
};

export const COLORS = {
  PRIMARY: '#0066CC',
  SECONDARY: '#0099CC',
  LIGHT_GRAY: '#EEEEEE',
  DARK_GRAY: '#666666',
  BLUE: '#007bff',
  INDIGO: '#6610f2',
  PURPLE: '#6f42c0',
  PINK: '#e83e8c',
  RED: '#dc3545',
  ORANGE: '#fd7e14',
  YELLOW: '#ffc107',
  GREEN: '#28a745',
  TEAL: '#20c997',
  CYAN: '#17a2b8',
  GRAY: '#6c757d',
  DARK_GRAY: '#343a40',
  BLACK: '#212529',
  WHITE: '#fff',
  TRANSPARENT: 'rgba(0, 0, 0, 0)',
};