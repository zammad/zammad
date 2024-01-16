import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const SessionFragmentDoc = gql`
    fragment session on Session {
  id
  afterAuth {
    type
    data
  }
}
    `;