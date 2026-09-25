import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const CtiSidebarAttributesFragmentDoc = gql`
    fragment ctiSidebarAttributes on CtiSidebar {
  unhandledCount
  ringingCalls {
    id
    direction
    state
    comment
    from
    fromPretty
    fromComment
    done
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
  }
}
    `;