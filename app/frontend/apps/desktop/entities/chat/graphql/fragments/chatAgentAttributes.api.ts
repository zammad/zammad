import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const ChatAgentAttributesFragmentDoc = gql`
    fragment chatAgentAttributes on User {
  id
  internalId
  firstname
  lastname
  fullname
  image
  vip
  outOfOffice
  outOfOfficeStartAt
  outOfOfficeEndAt
  active
}
    `;