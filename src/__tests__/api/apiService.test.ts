typescript
import { APIKEYS } from '../../api/APIKEYS';
import { getEvents, getTeams, getMatches, getInfo } from '../apiService';

describe('apiService', () => {
  const TOA_URL = APIKEYS.TOA_URL;

  it('should fetch events', async () => {
    const response = await getEvents();
    expect(response.status).toBe(200);
  });

  it('should fetch teams for a given event', async () => {
    const eventId = '1234';
    const response = await getTeams(eventId);
    expect(response.status).toBe(200);
  });

  it('should fetch matches for a given event', async () => {
    const eventId = '1234';
    const response = await getMatches(eventId);
    expect(response.status).toBe(200);
  });

  it('should fetch event information for a given event', async () => {
    const eventId = '1234';
    const response = await getInfo(eventId);
    expect(response.status).toBe(200);
  });
});