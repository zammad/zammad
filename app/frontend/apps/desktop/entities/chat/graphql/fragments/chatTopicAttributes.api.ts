import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const ChatTopicAttributesFragmentDoc = gql`
    fragment chatTopicAttributes on ChatTopic {
  id
  internalId
  name
  active
}
    `;