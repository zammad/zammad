import * as Types from '../types';

import gql from 'graphql-tag';
export const ObjectAttributeValuesFragmentDoc = gql`
    fragment objectAttributeValues on ObjectAttributeValue {
  attribute {
    name
    display
  }
  value
  renderedLink
}
    `;