import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const ChatMessageAttributesFragmentDoc = gql`
    fragment chatMessageAttributes on ChatMessage {
  id
  content
  createdAt
  createdBy {
    ...chatAgentAttributes
  }
}
    `;