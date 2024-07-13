typescript
import { renderHook } from '@testing-library/react-hooks';
import { useFetchData } from '../hooks/useFetchData';
import { APIKEYS } from '../../api/APIKEYS';
import { ResponseModel } from '../../functions/ResponseModel';

jest.mock('axios');

describe('useFetchData', () => {
  it('should fetch events data successfully', async () => {
    const mockedResponse = {
      data: {
        id: 'event_id',
        object: 'event',
        model: 'event_model',
        choices: [],
      },
    };

    const axiosMock = require('axios');
    axiosMock.get.mockResolvedValueOnce(mockedResponse);

    const { result, waitForNextUpdate } = renderHook(() =>
      useFetchData('events'),
    );

    await waitForNextUpdate();

    expect(result.current.data).toEqual(
      new ResponseModel(
        mockedResponse.data.id,
        mockedResponse.data.object,
        mockedResponse.data.model,
        mockedResponse.data.choices,
      ),
    );
  });

  it('should fetch teams data successfully', async () => {
    const mockedResponse = {
      data: {
        id: 'teams_id',
        object: 'teams',
        model: 'teams_model',
        choices: [],
      },
    };

    const axiosMock = require('axios');
    axiosMock.get.mockResolvedValueOnce(mockedResponse);

    const { result, waitForNextUpdate } = renderHook(() =>
      useFetchData('teams', 'event_id'),
    );

    await waitForNextUpdate();

    expect(result.current.data).toEqual(
      new ResponseModel(
        mockedResponse.data.id,
        mockedResponse.data.object,
        mockedResponse.data.model,
        mockedResponse.data.choices,
      ),
    );
  });

  it('should fetch matches data successfully', async () => {
    const mockedResponse = {
      data: {
        id: 'matches_id',
        object: 'matches',
        model: 'matches_model',
        choices: [],
      },
    };

    const axiosMock = require('axios');
    axiosMock.get.mockResolvedValueOnce(mockedResponse);

    const { result, waitForNextUpdate } = renderHook(() =>
      useFetchData('matches', 'event_id'),
    );

    await waitForNextUpdate();

    expect(result.current.data).toEqual(
      new ResponseModel(
        mockedResponse.data.id,
        mockedResponse.data.object,
        mockedResponse.data.model,
        mockedResponse.data.choices,
      ),
    );
  });

  it('should fetch event info data successfully', async () => {
    const mockedResponse = {
      data: {
        id: 'event_info_id',
        object: 'event_info',
        model: 'event_info_model',
        choices: [],
      },
    };

    const axiosMock = require('axios');
    axiosMock.get.mockResolvedValueOnce(mockedResponse);

    const { result, waitForNextUpdate } = renderHook(() =>
      useFetchData('info', 'event_id'),
    );

    await waitForNextUpdate();

    expect(result.current.data).toEqual(
      new ResponseModel(
        mockedResponse.data.id,
        mockedResponse.data.object,
        mockedResponse.data.model,
        mockedResponse.data.choices,
      ),
    );
  });

  it('should handle fetch errors', async () => {
    const axiosMock = require('axios');
    axiosMock.get.mockRejectedValueOnce(new Error('Network Error'));

    const { result, waitForNextUpdate } = renderHook(() =>
      useFetchData('events'),
    );

    await waitForNextUpdate();

    expect(result.current.error).toEqual(new Error('Network Error'));
  });
});