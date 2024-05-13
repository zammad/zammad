import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from './objectAttributeValues.api';
export const UserDetailAttributesFragmentDoc = gql`
    fragment userDetailAttributes on User {
  id
  internalId
  firstname
  lastname
  fullname
  outOfOffice
  outOfOfficeStartAt
  outOfOfficeEndAt
  image
  email
  web
  vip
  phone
  mobile
  fax
  note
  active
  objectAttributeValues {
    ...objectAttributeValues
  }
  organization {
    id
    internalId
    name
    active
    vip
    ticketsCount {
      open
      closed
    }
  }
  secondaryOrganizations(first: $secondaryOrganizationsCount) {
    edges {
      node {
        id
        internalId
        active
        name
      }
    }
    totalCount
  }
  hasSecondaryOrganizations
  ticketsCount {
    open
    closed
  }
}
    ${ObjectAttributeValuesFragmentDoc}`;