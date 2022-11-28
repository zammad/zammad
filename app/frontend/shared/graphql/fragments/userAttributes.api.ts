import * as Types from '../types';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from './objectAttributeValues.api';
export const UserAttributesFragmentDoc = gql`
    fragment userAttributes on User {
  id
  internalId
  firstname
  lastname
  fullname
  image
  preferences
  objectAttributeValues {
    ...objectAttributeValues
  }
  organization {
    id
    internalId
    name
    active
    objectAttributeValues {
      ...objectAttributeValues
    }
  }
  hasSecondaryOrganizations
}
    ${ObjectAttributeValuesFragmentDoc}`;