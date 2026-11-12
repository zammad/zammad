import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const ChatAgentStateAttributesFragmentDoc = gql`
    fragment chatAgentStateAttributes on ChatAgentState {
  active
  topics {
    ...chatTopicAttributes
  }
  waitingQueues {
    topic {
      ...chatTopicAttributes
    }
    sessions {
      ...chatSessionAttributes
    }
  }
  runningSessions {
    ...chatSessionAttributes
  }
  availableAgents {
    ...chatAgentAttributes
  }
  seatsAvailable
  seatsTotal
}
    `;