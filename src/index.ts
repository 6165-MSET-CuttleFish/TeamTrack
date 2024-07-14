import 'react-native';
import './App';

const App = () => <App />;

AppRegistry.registerComponent('TeamTrack', () => App);

AppRegistry.runApplication('TeamTrack', {
  rootTag: document.getElementById('root') as HTMLElement,
});