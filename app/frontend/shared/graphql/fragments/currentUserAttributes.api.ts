import * as Types from '../types';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from './objectAttributeValues.api';
export const CurrentUserAttributesFragmentDoc = gql`
    fragment currentUserAttributes on User {
  id
  firstname
  lastname
  fullname
  image
  preferences
  objectAttributeValues {
    ...objectAttributeValues
  }
  organization {
    name
    objectAttributeValues {
      ...objectAttributeValues
    }
  }
  permissions {
    names
  }
}
    ${ObjectAttributeValuesFragmentDoc}`;