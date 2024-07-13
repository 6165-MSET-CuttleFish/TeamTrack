typescript
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react-native';
import TeamCardList from '../TeamCardList';
import { Event, Team } from '../../models';

const mockEvent = new Event({
  teams: {
    '1': new Team({ number: 1, name: 'Team 1' }),
    '2': new Team({ number: 2, name: 'Team 2' }),
  },
  matches: {},
  userTeam: null,
  shared: false,
});

const mockStatConfig = {
  removeOutliers: false,
  showPenalties: false,
  allianceTotal: false,
  sorted: false,
};

describe('TeamCardList', () => {
  it('renders the team cards correctly', () => {
    render(<TeamCardList event={mockEvent} statConfig={mockStatConfig} />);

    expect(screen.getByText('Team 1')).toBeTruthy();
    expect(screen.getByText('Team 2')).toBeTruthy();
  });

  it('navigates to the team view when a team card is pressed', () => {
    const mockNavigate = jest.fn();

    render(
      <TeamCardList event={mockEvent} statConfig={mockStatConfig} navigation={{ navigate: mockNavigate }} />,
    );

    fireEvent.press(screen.getByText('Team 1'));

    expect(mockNavigate).toHaveBeenCalledWith('TeamView', {
      team: mockEvent.teams['1'],
      event: mockEvent,
    });
  });
});