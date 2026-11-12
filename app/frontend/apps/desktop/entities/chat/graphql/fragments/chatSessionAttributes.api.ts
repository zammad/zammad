import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const ChatSessionAttributesFragmentDoc = gql`
    fragment chatSessionAttributes on ChatSession {
  id
  internalId
  state
  name
  url
  remoteIp
  dnsName
  geoIp {
    countryName
    countryCode
    cityName
  }
  createdAt
  updatedAt
  topic {
    ...chatTopicAttributes
  }
  user {
    ...chatAgentAttributes
  }
}
    `;