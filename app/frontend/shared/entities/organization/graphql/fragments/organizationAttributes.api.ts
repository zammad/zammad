import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
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
  ticketsCount {
    open
    closed
  }
  objectAttributeValues {
    ...objectAttributeValues
  }
}
    ${ObjectAttributeValuesFragmentDoc}`;