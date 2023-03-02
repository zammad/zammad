import * as Types from '../../../../../../shared/graphql/types';

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
        active
        vip
      }
    }
    totalCount
  }
}
    `;