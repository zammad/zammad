// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
    id: convertToGraphQLId('Ticket::StateType', 2),
    name: 'open',
  },
}

export const defaultGroup = {
  __typename: 'Group',
  id: convertToGraphQLId('Group', 2),
  name: 'Test Agents',
  emailAddress: null,
  sharedDrafts: true,
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
export const createDummyTicket = <R = TicketQuery['ticket']>(options?: {
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
  subscribed?: TicketQuery['ticket']['subscribed']
  colorCode?: EnumTicketStateColorCode
  title?: TicketQuery['ticket']['title']
  number?: TicketQuery['ticket']['number']
  checklist?: TicketQuery['ticket']['checklist']
  referencingChecklistTickets?: TicketQuery['ticket']['referencingChecklistTickets']
  timeUnit?: TicketQuery['ticket']['timeUnit']
  timeUnitsPerType?: TicketQuery['ticket']['timeUnitsPerType']
  tags?: string[]
  externalReferences?: TicketQuery['ticket']['externalReferences']
  preferences?: TicketQuery['ticket']['preferences']
  sharedDraftZoomId?: number
  // eslint-disable-next-line sonarjs/cognitive-complexity
}): R => {
  return nullableMock({
    __typename: 'Ticket',
    createArticleType: {
      __typename: 'TicketArticleType',
      id: convertToGraphQLId('Ticket::Article', 5),
      name: options?.articleType || 'email',
    },
    id: convertToGraphQLId('Ticket', options?.ticketId || 1),
    internalId: options?.ticketId || 1,
    number: options?.number || '89002',
    title: options?.title || 'Test Ticket',
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
    tags: options?.tags || [],
    timeUnit: options?.timeUnit || null,
    timeUnitsPerType: options?.timeUnitsPerType || [],
    subscribed: options?.subscribed || false,
    preferences: options?.preferences || {},
    stateColorCode: options?.colorCode || EnumTicketStateColorCode.Open,
    firstResponseEscalationAt: null,
    closeEscalationAt: null,
    updateEscalationAt: null,
    externalReferences: options?.externalReferences,
    initialChannel: null,
    mentions: options?.mentions || defaultMentions,
    checklist: options?.checklist || null,
    referencingChecklistTickets: options?.referencingChecklistTickets || [],
    sharedDraftZoomId: options?.sharedDraftZoomId
      ? convertToGraphQLId('Ticket::SharedDraftZoom', options.sharedDraftZoomId)
      : null,
  }) as R
}
