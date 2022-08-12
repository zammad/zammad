import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../shared/graphql/fragments/objectAttributeValues.api';
export const OrganizationAttributesFragmentDoc = gql`
    fragment organizationAttributes on Organization {
  id
  name
  shared
  domain
  domainAssignment
  active
  note
  objectAttributeValues {
    ...objectAttributeValues
  }
}
    ${ObjectAttributeValuesFragmentDoc}`;