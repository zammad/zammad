import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const OrganizationMembersWithShowMoreFragmentDoc = gql`
    fragment organizationMembersWithShowMore on Organization {
  allMembers(first: $first, last: $last, after: $after) {
    edges {
      node {
        id
        internalId
        image
        firstname
        lastname
        fullname
        email
        phone
        outOfOffice
        outOfOfficeStartAt
        outOfOfficeEndAt
        active
        vip
      }
      cursor
    }
    pageInfo {
      endCursor
      startCursor
      hasNextPage
    }
    totalCount
  }
}
    `;