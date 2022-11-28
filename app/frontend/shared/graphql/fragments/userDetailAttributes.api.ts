import * as Types from '../types';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from './objectAttributeValues.api';
export const UserDetailAttributesFragmentDoc = gql`
    fragment userDetailAttributes on User {
  id
  internalId
  firstname
  lastname
  fullname
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
    ticketsCount {
      open
      closed
    }
  }
  hasSecondaryOrganizations
  ticketsCount {
    open
    closed
  }
}
    ${ObjectAttributeValuesFragmentDoc}`;