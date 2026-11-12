import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
export const OrganizationAttributesFragmentDoc = gql`
    fragment organizationAttributes on Organization {
  id
  internalId
  name
  shared
  domain
  domainAssignment
  active
  note
  vip
  objectAttributeValues {
    ...objectAttributeValues
  }
}
    `;