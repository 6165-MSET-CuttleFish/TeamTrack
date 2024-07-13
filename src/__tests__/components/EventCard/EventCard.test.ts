typescript
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react-native';
import EventCard from '../../components/EventCard/EventCard';
import { Event } from '../../models/Event';

describe('EventCard', () => {
  const mockEvent = new Event({
    id: 'test-event',
    name: 'Test Event',
    type: 'local',
    gameName: 'Test Game',
    shared: false,
    createdAt: new Date(),
    matches: [],
  });

  it('renders event name correctly', () => {
    render(<EventCard event={mockEvent} />);
    expect(screen.getByText('Test Event')).toBeTruthy();
  });

  it('renders event type correctly', () => {
    render(<EventCard event={mockEvent} />);
    expect(screen.getByText('In Person Event')).toBeTruthy();
  });

  it('renders event date correctly', () => {
    const dateString = new Date(mockEvent.createdAt).toLocaleDateString();
    render(<EventCard event={mockEvent} />);
    expect(screen.getByText(dateString)).toBeTruthy();
  });

  it('renders shared icon correctly', () => {
    render(<EventCard event={mockEvent} />);
    expect(screen.getByTestId('shared-icon')).toBeInTheDocument();
  });

  it('calls onTap function when pressed', () => {
    const mockOnTap = jest.fn();
    render(<EventCard event={mockEvent} onTap={mockOnTap} />);
    fireEvent.press(screen.getByTestId('event-card'));
    expect(mockOnTap).toHaveBeenCalledWith(mockEvent);
  });
});