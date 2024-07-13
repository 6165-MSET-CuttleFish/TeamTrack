typescript
import 'react-native';
import 'react-native-testing-library';
import { render, screen, fireEvent } from '@testing-library/react-native';
import App from '../App';

describe('App', () => {
  it('renders the App component', () => {
    render(<App />);
    expect(screen.getByText('TeamTrack')).toBeTruthy();
  });
});