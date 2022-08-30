import * as Types from '../types';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from './objectAttributeValues.api';
export const UserAttributesFragmentDoc = gql`
    fragment userAttributes on User {
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
}
    ${ObjectAttributeValuesFragmentDoc}`;