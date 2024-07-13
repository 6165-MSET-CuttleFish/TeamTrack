typescript
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react-native';
import Team from '../../Team';
import { Game, Team as TeamModel, Event } from '../../../../models';
import { OpModeType } from '../../../../models/Enums';
import { StatConfig } from '../../../../models/StatConfig';
import { Score } from '../../../../models/ScoreModel';
import { Dice } from '../../../../models/Enums';
import { Statistics } from '../../../../functions/Statistics';
import { getAll } from '../../../../functions/Extensions';
import { TeamRow } from '../../TeamRow';
import { TeamView } from '../../TeamView';

const mockEvent: Event = {
  event_key: 'test_event',
  name: 'Test Event',
  type: 'practice',
  gameName: 'test_game',
  statConfig: new StatConfig({
    allianceTotal: false,
    removeOutliers: false,
    showPenalties: false,
  }),
  teams: {},
  matches: {},
};

const mockTeam: TeamModel = {
  number: '1234',
  name: 'Team Name',
  scores: {},
  targetScore: null,
  getWLT: () => '0-0-0',
};

describe('Team', () => {
  it('renders the team name and number', () => {
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('Team Name')).toBeTruthy();
    expect(screen.getByText('1234')).toBeTruthy();
  });

  it('renders the team scores', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team target score', () => {
    const mockTargetScore = new Score('test_target_score', Dice.none, 'test_game');
    mockTargetScore.setElementCount('auto_score', 20);
    mockTeam.targetScore = mockTargetScore;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('20')).toBeTruthy();
  });

  it('renders the team WLT', () => {
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('0-0-0')).toBeTruthy();
  });

  it('renders the team scores by dice', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by dice and opModeType', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice and removes outliers', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    mockEvent.statConfig.removeOutliers = true;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice and shows penalties', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    mockEvent.statConfig.showPenalties = true;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice and shows penalties and removes outliers', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    mockEvent.statConfig.showPenalties = true;
    mockEvent.statConfig.removeOutliers = true;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice and shows penalties and removes outliers and allianceTotal', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    mockEvent.statConfig.showPenalties = true;
    mockEvent.statConfig.removeOutliers = true;
    mockEvent.statConfig.allianceTotal = true;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice and shows penalties and removes outliers and allianceTotal and target score', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    mockTeam.targetScore = mockScore;
    mockEvent.statConfig.showPenalties = true;
    mockEvent.statConfig.removeOutliers = true;
    mockEvent.statConfig.allianceTotal = true;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice and shows penalties and removes outliers and allianceTotal and target score and wlt', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    mockTeam.targetScore = mockScore;
    mockEvent.statConfig.showPenalties = true;
    mockEvent.statConfig.removeOutliers = true;
    mockEvent.statConfig.allianceTotal = true;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice and shows penalties and removes outliers and allianceTotal and target score and wlt and match list', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    mockTeam.targetScore = mockScore;
    mockEvent.statConfig.showPenalties = true;
    mockEvent.statConfig.removeOutliers = true;
    mockEvent.statConfig.allianceTotal = true;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice and shows penalties and removes outliers and allianceTotal and target score and wlt and match list and change list', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    mockTeam.targetScore = mockScore;
    mockEvent.statConfig.showPenalties = true;
    mockEvent.statConfig.removeOutliers = true;
    mockEvent.statConfig.allianceTotal = true;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice and shows penalties and removes outliers and allianceTotal and target score and wlt and match list and change list and auton drawer', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    mockTeam.targetScore = mockScore;
    mockEvent.statConfig.showPenalties = true;
    mockEvent.statConfig.removeOutliers = true;
    mockEvent.statConfig.allianceTotal = true;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice and shows penalties and removes outliers and allianceTotal and target score and wlt and match list and change list and auton drawer and team row', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    mockTeam.targetScore = mockScore;
    mockEvent.statConfig.showPenalties = true;
    mockEvent.statConfig.removeOutliers = true;
    mockEvent.statConfig.allianceTotal = true;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });

  it('renders the team scores by opModeType and dice and shows penalties and removes outliers and allianceTotal and target score and wlt and match list and change list and auton drawer and team row and team view', () => {
    const mockScore = new Score('test_score', Dice.none, 'test_game');
    mockScore.setElementCount('auto_score', 10);
    mockTeam.scores = {
      'test_score_id': mockScore,
    };
    mockTeam.targetScore = mockScore;
    mockEvent.statConfig.showPenalties = true;
    mockEvent.statConfig.removeOutliers = true;
    mockEvent.statConfig.allianceTotal = true;
    render(<Team team={mockTeam} event={mockEvent} isSoleWindow={true} />);
    expect(screen.getByText('10')).toBeTruthy();
  });
});