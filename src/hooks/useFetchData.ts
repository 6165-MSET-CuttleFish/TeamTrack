typescript
import { useState, useEffect } from 'react';
import { useNavigation } from '@react-navigation/native';
import { API_KEYS } from '../api/APIKEYS';
import { useToast } from 'react-native-toast-notifications';

const TOA_URL = API_KEYS.TOA_URL;

export const useFetchData = (id: string) => {
  const [isLoading, setIsLoading] = useState(false);
  const [data, setData] = useState<any>(null);
  const [error, setError] = useState(null);
  const toast = useToast();
  const navigation = useNavigation();

  const fetchEvents = async () => {
    setIsLoading(true);
    try {
      const response = await fetch(`${TOA_URL}/event`, {
        headers: {
          'X-TOA-Key': API_KEYS.TOA_KEY,
          'X-Application-Origin': 'TeamTrack',
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setData(data);
      } else {
        setError('Error fetching events');
      }
    } catch (err) {
      setError('Network error');
    } finally {
      setIsLoading(false);
    }
  };

  const fetchTeams = async (id: string) => {
    setIsLoading(true);
    try {
      const response = await fetch(`${TOA_URL}/event/${id}/teams`, {
        headers: {
          'X-TOA-Key': API_KEYS.TOA_KEY,
          'X-Application-Origin': 'TeamTrack',
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setData(data);
      } else {
        setError('Error fetching teams');
      }
    } catch (err) {
      setError('Network error');
    } finally {
      setIsLoading(false);
    }
  };

  const fetchMatches = async (id: string) => {
    setIsLoading(true);
    try {
      const response = await fetch(`${TOA_URL}/event/${id}/matches`, {
        headers: {
          'X-TOA-Key': API_KEYS.TOA_KEY,
          'X-Application-Origin': 'TeamTrack',
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setData(data);
      } else {
        setError('Error fetching matches');
      }
    } catch (err) {
      setError('Network error');
    } finally {
      setIsLoading(false);
    }
  };

  const fetchInfo = async (id: string) => {
    setIsLoading(true);
    try {
      const response = await fetch(`${TOA_URL}/event/${id}`, {
        headers: {
          'X-TOA-Key': API_KEYS.TOA_KEY,
          'X-Application-Origin': 'TeamTrack',
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setData(data);
      } else {
        setError('Error fetching info');
      }
    } catch (err) {
      setError('Network error');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (id) {
      fetchInfo(id);
    } else {
      fetchEvents();
    }
  }, [id]);

  return {
    isLoading,
    data,
    error,
    fetchTeams,
    fetchMatches,
    fetchInfo,
  };
};