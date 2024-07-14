import axios from 'axios';
import {
  Event,
  EventResponse,
  GetMatchResponse,
  GetTeamResponse,
  Match,
  Team,
} from '../types';

const API_URL = 'https://www.thebluealliance.com/api/v3';
const API_KEY = 'YOUR_API_KEY'; // Replace with your actual API key

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'X-TBA-Auth-Key': API_KEY,
  },
});

export const getEvents = async (): Promise<EventResponse> => {
  const response = await api.get('/events');
  return response.data;
};

export const getEvent = async (eventId: string): Promise<Event> => {
  const response = await api.get(`/event/${eventId}`);
  return response.data;
};

export const getTeams = async (eventId: string): Promise<GetTeamResponse> => {
  const response = await api.get(`/event/${eventId}/teams`);
  return response.data;
};

export const getTeam = async (teamKey: string): Promise<Team> => {
  const response = await api.get(`/team/${teamKey}`);
  return response.data;
};

export const getMatches = async (eventId: string): Promise<GetMatchResponse> => {
  const response = await api.get(`/event/${eventId}/matches`);
  return response.data;
};

export const getMatch = async (matchKey: string): Promise<Match> => {
  const response = await api.get(`/match/${matchKey}`);
  return response.data;
};

export default api;