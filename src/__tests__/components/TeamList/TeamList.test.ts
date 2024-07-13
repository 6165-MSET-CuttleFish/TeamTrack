typescript
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react-native';
import TeamList from '../../TeamList';
import { Event, Team } from '../../../models';
import { StatConfig, OpModeType, ScoringElement } from '../../../models/StatConfig';
import { Statistics } from '../../../functions/Statistics';

describe('TeamList', () => {
  const mockEvent = new Event({
    teams: {
      '1': new Team({ number: 1, name: 'Team 1' }),
      '2': new Team({ number: 2, name: 'Team 2' }),
    },
    matches: {},
    userTeam: { number: 1 },
  });

  const mockStatConfig = new StatConfig({
    removeOutliers: false,
    showPenalties: false,
    allianceTotal: false,
    sorted: false,
  });

  const mockStatistics = new Statistics(mockStatConfig);

  it('renders correctly', () => {
    render(<TeamList event={mockEvent} statConfig={mockStatConfig} statistics={mockStatistics} />);

    expect(screen.getByText('Team 1')).toBeTruthy();
    expect(screen.getByText('Team 2')).toBeTruthy();
  });

  it('renders correctly when sorted', () => {
    const sortedStatConfig = new StatConfig({
      removeOutliers: false,
      showPenalties: false,
      allianceTotal: false,
      sorted: true,
    });
    render(
      <TeamList event={mockEvent} statConfig={sortedStatConfig} statistics={mockStatistics} />,
    );

    expect(screen.getByText('Team 1')).toBeTruthy();
    expect(screen.getByText('Team 2')).toBeTruthy();
  });

  it('renders correctly when alliance total is enabled', () => {
    const allianceTotalStatConfig = new StatConfig({
      removeOutliers: false,
      showPenalties: false,
      allianceTotal: true,
      sorted: false,
    });
    render(
      <TeamList event={mockEvent} statConfig={allianceTotalStatConfig} statistics={mockStatistics} />,
    );

    expect(screen.getByText('Team 1')).toBeTruthy();
    expect(screen.getByText('Team 2')).toBeTruthy();
  });

  it('renders correctly with empty team list', () => {
    const emptyEvent = new Event({
      teams: {},
      matches: {},
      userTeam: { number: 1 },
    });
    render(<TeamList event={emptyEvent} statConfig={mockStatConfig} statistics={mockStatistics} />);

    expect(screen.getByText('No teams found')).toBeTruthy();
  });

  it('navigates to TeamView on team press', () => {
    const mockNavigation = {
      navigate: jest.fn(),
    };
    render(<TeamList event={mockEvent} statConfig={mockStatConfig} statistics={mockStatistics} />, {
      wrapper: ({ children }) => <NavigationContext.Provider value={mockNavigation}>{children}</NavigationContext.Provider>,
    });

    fireEvent.press(screen.getByText('Team 1'));

    expect(mockNavigation.navigate).toHaveBeenCalledWith('TeamView', {
      team: mockEvent.teams['1'],
      event: mockEvent,
    });
  });
});