import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const OrganizationMembersWithFetchMoreFragmentDoc = gql`
    fragment organizationMembersWithFetchMore on Organization {
  allMembers(first: $first, after: $after) {
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
    }
    pageInfo {
      endCursor
    }
    totalCount
  }
}
    `;