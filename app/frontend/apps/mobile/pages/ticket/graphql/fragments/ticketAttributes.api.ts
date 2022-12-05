import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from '../../../../../../shared/graphql/fragments/objectAttributeValues.api';
export const TicketAttributesFragmentDoc = gql`
    fragment ticketAttributes on Ticket {
  id
  internalId
  number
  title
  createdAt
  updatedAt
  pendingTime
  owner {
    id
    internalId
    firstname
    lastname
  }
  customer {
    id
    internalId
    firstname
    lastname
    fullname
    image
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
  organization {
    id
    internalId
    name
  }
  state {
    id
    name
    stateType {
      name
    }
  }
  group {
    id
    name
  }
  priority {
    id
    name
    defaultCreate
    uiColor
  }
  objectAttributeValues {
    ...objectAttributeValues
  }
  tags
  subscribed
}
    ${ObjectAttributeValuesFragmentDoc}`;