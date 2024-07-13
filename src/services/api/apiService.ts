typescript
import axios from 'axios';
import { APIKEYS } from '../api/APIKEYS';

const TOA_URL = APIKEYS.TOA_URL;

export const apiService = {
  getEvents: async () => {
    try {
      const response = await axios.get(`${TOA_URL}/event`, {
        headers: {
          'X-TOA-Key': APIKEYS.TOA_KEY,
          'X-Application-Origin': 'TeamTrack',
          'Content-Type': 'application/json',
        },
      });
      return response.data;
    } catch (error) {
      console.error('Error fetching events:', error);
      throw error;
    }
  },
  getTeams: async (id: string) => {
    try {
      const response = await axios.get(`${TOA_URL}/event/${id}/teams`, {
        headers: {
          'X-TOA-Key': APIKEYS.TOA_KEY,
          'X-Application-Origin': 'TeamTrack',
          'Content-Type': 'application/json',
        },
      });
      return response.data;
    } catch (error) {
      console.error('Error fetching teams:', error);
      throw error;
    }
  },
  getMatches: async (id: string) => {
    try {
      const response = await axios.get(`${TOA_URL}/event/${id}/matches`, {
        headers: {
          'X-TOA-Key': APIKEYS.TOA_KEY,
          'X-Application-Origin': 'TeamTrack',
          'Content-Type': 'application/json',
        },
      });
      return response.data;
    } catch (error) {
      console.error('Error fetching matches:', error);
      throw error;
    }
  },
  getInfo: async (id: string) => {
    try {
      const response = await axios.get(`${TOA_URL}/event/${id}`, {
        headers: {
          'X-TOA-Key': APIKEYS.TOA_KEY,
          'X-Application-Origin': 'TeamTrack',
          'Content-Type': 'application/json',
        },
      });
      return response.data;
    } catch (error) {
      console.error('Error fetching event info:', error);
      throw error;
    }
  },
};