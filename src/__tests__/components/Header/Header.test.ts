typescript
import React from 'react';
import { render, screen } from '@testing-library/react-native';
import Header from '../../src/components/Header/Header';

describe('Header', () => {
  it('renders the title', () => {
    render(<Header title="Test Title" />);
    expect(screen.getByText('Test Title')).toBeTruthy();
  });

  it('renders the subtitle', () => {
    render(<Header title="Test Title" subtitle="Test Subtitle" />);
    expect(screen.getByText('Test Subtitle')).toBeTruthy();
  });

  it('renders the back button', () => {
    render(<Header title="Test Title" showBackButton={true} />);
    expect(screen.getByRole('button', { name: 'Back' })).toBeTruthy();
  });

  it('calls the onBackPress function when back button is pressed', () => {
    const onBackPress = jest.fn();
    render(<Header title="Test Title" showBackButton={true} onBackPress={onBackPress} />);
    screen.getByRole('button', { name: 'Back' }).press();
    expect(onBackPress).toHaveBeenCalledTimes(1);
  });
});