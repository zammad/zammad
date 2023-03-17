import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../shared/graphql/fragments/objectAttributeValues.api';
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
  ticketsCount {
    open
    closed
  }
  objectAttributeValues {
    ...objectAttributeValues
  }
}
    ${ObjectAttributeValuesFragmentDoc}`;