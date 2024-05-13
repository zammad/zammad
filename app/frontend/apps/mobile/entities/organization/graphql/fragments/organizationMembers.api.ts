import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const OrganizationMembersFragmentDoc = gql`
    fragment organizationMembers on Organization {
  members(first: $membersCount) {
    edges {
      node {
        id
        internalId
        image
        firstname
        lastname
        fullname
        outOfOffice
        outOfOfficeStartAt
        outOfOfficeEndAt
        active
        vip
      }
    }
    totalCount
  }
}
    `;