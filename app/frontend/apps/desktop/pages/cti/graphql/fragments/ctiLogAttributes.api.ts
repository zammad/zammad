import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const CtiLogAttributesFragmentDoc = gql`
    fragment ctiLogAttributes on CtiLog {
  id
  direction
  state
  comment
  from
  to
  fromPretty
  toPretty
  fromComment
  toComment
  done
  durationWaitingTime
  durationTalkingTime
  createdAt
  fromMatches {
    level
    comment
    user {
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
  }
  toMatches {
    level
    comment
    user {
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
  }
}
    `;