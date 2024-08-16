// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { nullableMock } from '#tests/support/utils.ts'

import type { TicketQuery } from '#shared/graphql/types.ts'
import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

export const mockTicketCreateDate = new Date(2011, 11, 11, 11, 11, 11, 11)
export const mockTicketUpdateDate = new Date(2011, 12, 12, 12, 12, 12, 12)

export const defaultOwner = {
  __typename: 'User',
  id: convertToGraphQLId('User', 1),
  internalId: 1,
  firstname: 'Foo',
  lastname: 'Test',
}

export const defaultOrganization = {
  __typename: 'Organization',
  id: convertToGraphQLId('Organization', 1),
  internalId: 1,
  name: 'Zammad Foundation',
  vip: false,
  active: true,
}

export const defaultCustomer = {
  __typename: 'User',
  id: convertToGraphQLId('User', 2),
  internalId: 2,
  firstname: 'Nicole',
  lastname: 'Braun',
  fullname: 'Nicole Braun',
  phone: '',
  mobile: '',
  image: null,
  vip: false,
  active: true,
  outOfOffice: false,
  outOfOfficeStartAt: null,
  outOfOfficeEndAt: null,
  email: 'nicole.braun@zammad.org',
  organization: {
    __typename: 'Organization',
    id: convertToGraphQLId('Organization', 1),
    internalId: 1,
    name: 'Zammad Foundation',
    active: true,
    objectAttributeValues: [],
  },
  hasSecondaryOrganizations: true,
  policy: { __typename: 'PolicyDefault', update: true },
}

export const defaultState = {
  __typename: 'TicketState',
  id: convertToGraphQLId('Ticket::State', 2),
  name: 'open',
  stateType: {
    __typename: 'TicketStateType',
    name: 'open',
  },
}

export const defaultGroup = {
  __typename: 'Group',
  id: convertToGraphQLId('Group', 2),
  name: 'Test Agents',
  emailAddress: null,
}

export const defaultPriority = {
  __typename: 'TicketPriority',
  id: 'gid://zammad/Ticket::Priority/2',
  name: '2 normal',
  defaultCreate: true,
  uiColor: null,
}

export const defaultPolicy = {
  __typename: 'PolicyTicket',
  update: true,
  agentReadAccess: true,
}

export const defaultMentions = {
  __typename: 'Mentions',
  totalCount: 0,
  edges: [],
}

/**
 * Options: can be expanded
 * Make sure to set old values as defaults to be backwards compatible
 * * */
export const createDummyTicket = (options?: {
  ticketId?: string
  owner?: TicketQuery['ticket']['owner']
  customer?: TicketQuery['ticket']['customer']
  organization?: TicketQuery['ticket']['organization']
  state?: TicketQuery['ticket']['state']
  articleType?: string
  group?: TicketQuery['ticket']['group']
  defaultPriority?: TicketQuery['ticket']['priority']
  defaultPolicy?: TicketQuery['ticket']['policy']
  mentions?: TicketQuery['ticket']['mentions']
  colorCode?: EnumTicketStateColorCode
}) => {
  return nullableMock({
    __typename: 'Ticket',
    createArticleType: {
      __typename: 'TicketArticleType',
      id: convertToGraphQLId('Ticket::Article', 5),
      name: options?.articleType || 'email',
    },
    id: convertToGraphQLId('Ticket', options?.ticketId || 1),
    internalId: options?.ticketId || 1,
    number: '89002',
    title: 'Test Ticket',
    createdAt: mockTicketCreateDate.toISOString(),
    escalationAt: null,
    updatedAt: mockTicketUpdateDate.toISOString(),
    pendingTime: null,
    owner: options?.owner === undefined ? defaultOwner : options?.owner,
    customer:
      options?.customer === undefined ? defaultCustomer : options?.customer,
    organization:
      options?.organization === undefined
        ? defaultOrganization
        : options?.organization,
    state: options?.state === undefined ? defaultState : options?.state,
    group: options?.group === undefined ? defaultGroup : options?.group,
    priority:
      options?.defaultPriority === undefined
        ? defaultPriority
        : options?.defaultPriority,
    objectAttributeValues: [],
    policy:
      options?.defaultPolicy === undefined
        ? defaultPolicy
        : options?.defaultPolicy,
    tags: [],
    timeUnit: null,
    timeUnitsPerType: [],
    subscribed: false,
    preferences: {},
    stateColorCode: options?.colorCode || EnumTicketStateColorCode.Open,
    firstResponseEscalationAt: null,
    closeEscalationAt: null,
    updateEscalationAt: null,
    initialChannel: null,
    mentions: options?.mentions || defaultMentions,
  }) as TicketQuery['ticket']
}
