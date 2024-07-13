typescript
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react-native';
import Teams from '../../components/Teams/Teams';
import { Event, Team, StatConfig, OpModeType, ScoringElement, Statistics } from '../../models';

// Mock data
const mockEvent: Event = {
  teams: {
    '1': {
      number: 1,
      name: 'Team 1',
      // ... other team properties
    },
    '2': {
      number: 2,
      name: 'Team 2',
      // ... other team properties
    },
    '3': {
      number: 3,
      name: 'Team 3',
      // ... other team properties
    },
  },
  matches: {
    // ... mock matches
  },
  userTeam: {
    number: 1,
    // ... other team properties
  },
  shared: true,
};

const mockStatConfig: StatConfig = {
  allianceTotal: false,
  removeOutliers: false,
  showPenalties: false,
  sorted: false,
};

const mockStatistics: Statistics = {
  getFunction: () => () => 0,
};

describe('Teams', () => {
  it('renders the team list correctly', () => {
    render(<Teams event={mockEvent} statConfig={mockStatConfig} statistics={mockStatistics} />);

    // Assertions about the rendered elements
    expect(screen.getByText('Team 1')).toBeTruthy();
    expect(screen.getByText('Team 2')).toBeTruthy();
    expect(screen.getByText('Team 3')).toBeTruthy();
  });

  it('navigates to TeamView on team press', () => {
    const mockNavigation = {
      navigate: jest.fn(),
    };
    render(<Teams event={mockEvent} statConfig={mockStatConfig} statistics={mockStatistics} navigation={mockNavigation} />);

    fireEvent.press(screen.getByText('Team 1'));

    expect(mockNavigation.navigate).toHaveBeenCalledWith('TeamView', {
      team: mockEvent.teams['1'],
      event: mockEvent,
    });
  });

  it('shows a progress indicator when event data is loading', () => {
    const mockEvent: Event = {
      ...mockEvent,
      shared: false,
    };
    render(<Teams event={mockEvent} statConfig={mockStatConfig} statistics={mockStatistics} />);

    expect(screen.getByText('Loading...')).toBeTruthy();
  });

  // Add more test cases for other scenarios like sorting, filtering, etc.
});