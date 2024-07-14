import { EventType, Event } from '../../api/api.types';

export interface EventListScreenProps {
  events: Event[];
  onEventPress: (event: Event) => void;
}

export interface EventListItemProps {
  event: Event;
  onEventPress: (event: Event) => void;
}

export type EventListScreenNavigationProps = {
  navigation: {
    navigate: (screen: string, params?: any) => void;
  };
};

export interface EventListItemData {
  id: string;
  name: string;
  type: EventType;
  createdAt: Date;
  shared: boolean;
  matches: string[];
}

export interface EventListScreenContext {
  events: Event[];
  setEvents: (events: Event[]) => void;
  isLoading: boolean;
  setIsLoading: (isLoading: boolean) => void;
  navigation: EventListScreenNavigationProps['navigation'];
}