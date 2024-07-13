typescript
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react-native';
import TeamCard from '../TeamCard';
import { OpModeType } from '../../../models/GameModel';

describe('TeamCard', () => {
  const mockNavigation = {
    navigate: jest.fn(),
  };

  const mockGame = {
    name: 'Test Game',
    type: OpModeType.Attack,
    scores: [],
  };

  it('renders correctly', () => {
    render(<TeamCard game={mockGame} navigation={mockNavigation} />);

    expect(screen.getByText('Test Game')).toBeInTheDocument();
    expect(screen.getByText('tap for details')).toBeInTheDocument();
  });

  it('navigates to details screen on press', () => {
    render(<TeamCard game={mockGame} navigation={mockNavigation} />);

    fireEvent.press(screen.getByText('Test Game'));

    expect(mockNavigation.navigate).toHaveBeenCalledWith('GameDetails', {
      game: mockGame,
    });
  });

  it('shows alert if not enough data', () => {
    const mockAlert = jest.fn();
    const mockGame = {
      name: 'Test Game',
      type: OpModeType.Attack,
      scores: [],
    };

    render(
      <TeamCard game={mockGame} navigation={mockNavigation} alert={mockAlert} />,
    );

    fireEvent.press(screen.getByText('Test Game'));

    expect(mockAlert).toHaveBeenCalledWith('Not Enough Data', 'Add more scores');
  });
});