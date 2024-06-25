import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ObjectAttributeValuesFragmentDoc } from '../../../../graphql/fragments/objectAttributeValues.api';
export const TicketAttributesFragmentDoc = gql`
    fragment ticketAttributes on Ticket {
  id
  internalId
  number
  title
  createdAt
  escalationAt
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
    phone
    mobile
    image
    vip
    active
    outOfOffice
    outOfOfficeStartAt
    outOfOfficeEndAt
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
    vip
    active
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
    agentReadAccess
  }
  tags
  timeUnit
  timeUnitsPerType {
    name
    timeUnit
  }
  subscribed
  preferences
  stateColorCode
  firstResponseEscalationAt
  closeEscalationAt
  updateEscalationAt
  initialChannel
}
    ${ObjectAttributeValuesFragmentDoc}`;