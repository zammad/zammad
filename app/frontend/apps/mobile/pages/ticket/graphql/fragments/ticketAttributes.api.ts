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
    email
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
    policy {
      update
    }
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
    emailAddress {
      name
      emailAddress
    }
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
  policy {
    update
  }
  tags
  subscribed
  preferences
}
    ${ObjectAttributeValuesFragmentDoc}`;