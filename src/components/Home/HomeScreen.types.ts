import { EventType, Role } from '../../api/api.types';
import { Team } from '../../api/api.types';
import { Match } from '../../api/api.types';
import { Event } from '../../api/api.types';

export interface HomeScreenProps {
  events: Event[];
  currentUser: {
    uid: string;
    email: string;
    role: Role;
  } | null;
  selectedEvent: Event | null;
  onEventSelect: (event: Event) => void;
  onCreateEvent: () => void;
  onEventShare: (event: Event) => void;
  onDeleteEvent: (event: Event) => void;
}

export interface HomeScreenData {
  events: Event[];
  currentUser: {
    uid: string;
    email: string;
    role: Role;
  } | null;
  selectedEvent: Event | null;
}

export interface HomeScreenState {
  events: Event[];
  currentUser: {
    uid: string;
    email: string;
    role: Role;
  } | null;
  selectedEvent: Event | null;
}