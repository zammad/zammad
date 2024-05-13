import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const TokenAttributesFragmentDoc = gql`
    fragment tokenAttributes on Token {
  id
  user {
    id
  }
  name
  preferences
  expiresAt
  lastUsedAt
  createdAt
}
    `;