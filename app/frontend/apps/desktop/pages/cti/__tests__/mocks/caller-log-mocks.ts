// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import FormUpdaterUser from '#tests/graphql/factories/types/FormUpdaterUser.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { CallerLogEntry, CallerLogMatch, RingingCall } from '../../types.ts'

export const knownCustomer = {
  __typename: 'User' as const,
  id: convertToGraphQLId('User', 2),
  internalId: 2,
  firstname: 'Franz',
  lastname: 'Bauer',
  fullname: 'Franz Bauer',
  image: null,
  vip: false,
  outOfOffice: false,
  outOfOfficeStartAt: null,
  outOfOfficeEndAt: null,
  active: true,
}

export const knownMatch: CallerLogMatch = {
  __typename: 'CtiLogCallerIdMatch',
  level: 'known',
  comment: null,
  user: knownCustomer,
}

// A caller ID can be matched by a comment alone, without a user record behind it.
export const commentOnlyMatch: CallerLogMatch = {
  __typename: 'CtiLogCallerIdMatch',
  level: 'maybe',
  comment: 'Carla Weber',
  user: null,
}

export const possibleMatches: CallerLogMatch[] = [
  {
    __typename: 'CtiLogCallerIdMatch',
    level: 'maybe',
    comment: 'Anna Lena',
    user: {
      ...knownCustomer,
      id: convertToGraphQLId('User', 3),
      internalId: 3,
      firstname: 'Anna',
      lastname: 'Lena',
      fullname: 'Anna Lena',
    },
  },
  // Sits between the two user matches, so both shapes are covered in the avatar stack and the list.
  commentOnlyMatch,
  {
    __typename: 'CtiLogCallerIdMatch',
    level: 'maybe',
    comment: 'Bob Smith',
    user: {
      ...knownCustomer,
      id: convertToGraphQLId('User', 4),
      internalId: 4,
      firstname: 'Bob',
      lastname: 'Smith',
      fullname: 'Bob Smith',
    },
  },
]

const baseEntry = {
  __typename: 'CtiLog' as const,
  from: '4930609854180',
  to: '4930609811111',
  fromPretty: '+49 30 609854180',
  toPretty: '+49 30 609811111',
  fromComment: null,
  toComment: null,
  durationWaitingTime: 20,
  durationTalkingTime: null,
  createdAt: '2026-09-21T09:00:00Z',
  fromMatches: [],
  toMatches: [],
}

export const missedCall: CallerLogEntry = {
  ...baseEntry,
  id: convertToGraphQLId('Cti::Log', 1),
  direction: 'in',
  state: 'hangup',
  comment: 'noAnswer',
  done: false,
  fromMatches: [knownMatch],
}

export const checkedCall: CallerLogEntry = {
  ...baseEntry,
  id: convertToGraphQLId('Cti::Log', 2),
  direction: 'in',
  state: 'hangup',
  comment: 'normalClearing',
  done: true,
  durationTalkingTime: 45,
  fromMatches: [knownMatch],
  toComment: 'Bob Smith',
}

export const callWithPossibleCallers: CallerLogEntry = {
  ...baseEntry,
  id: convertToGraphQLId('Cti::Log', 3),
  direction: 'in',
  state: 'newCall',
  comment: null,
  done: false,
  durationWaitingTime: null,
  fromMatches: possibleMatches,
}

export const callFromUnknown: CallerLogEntry = {
  ...baseEntry,
  id: convertToGraphQLId('Cti::Log', 4),
  direction: 'in',
  state: 'answer',
  comment: null,
  done: true,
  from: '4912345678',
  fromPretty: '+49 12345678',
}

export const outboundCall: CallerLogEntry = {
  ...baseEntry,
  id: convertToGraphQLId('Cti::Log', 5),
  direction: 'out',
  state: 'hangup',
  comment: 'busy',
  done: true,
  toMatches: [knownMatch],
}

export const callWithCommentMatch: CallerLogEntry = {
  ...baseEntry,
  id: convertToGraphQLId('Cti::Log', 6),
  direction: 'in',
  state: 'answer',
  comment: null,
  done: false,
  fromMatches: [commentOnlyMatch],
}

// The telephony backend named the caller, but the matched user has been deleted since.
export const callFromDeletedUser: CallerLogEntry = {
  ...baseEntry,
  id: convertToGraphQLId('Cti::Log', 10),
  direction: 'in',
  state: 'hangup',
  comment: 'noAnswer',
  done: false,
  from: '4912345678',
  fromPretty: '+49 12345678',
  fromComment: 'Carla Weber',
}

export const callerLogEntries = [
  missedCall,
  checkedCall,
  callWithPossibleCallers,
  callFromUnknown,
  outboundCall,
]

export const callerLogHeaders = ['from', 'to', 'status', 'waiting', 'duration', 'created_at']

const baseRingingCall = {
  __typename: 'CtiLog' as const,
  direction: 'in',
  state: 'newCall',
  comment: null,
  from: '4930609854180',
  fromPretty: '+49 30 609854180',
  fromComment: null,
  done: false,
  createdAt: '2026-09-21T09:00:00Z',
}

export const ringingCallFromKnownCaller: RingingCall = {
  ...baseRingingCall,
  id: convertToGraphQLId('Cti::Log', 7),
  fromMatches: [knownMatch],
}

export const ringingCallFromPossibleCaller: RingingCall = {
  ...baseRingingCall,
  id: convertToGraphQLId('Cti::Log', 9),
  fromMatches: [commentOnlyMatch],
}

export const ringingCallFromUnknownCaller: RingingCall = {
  ...baseRingingCall,
  id: convertToGraphQLId('Cti::Log', 8),
  from: '4912345678',
  fromPretty: '+49 12345678',
  fromMatches: [],
}

export const ringingCallFromPossibleCallers: RingingCall = {
  ...baseRingingCall,
  id: convertToGraphQLId('Cti::Log', 11),
  from: '4930456646543',
  fromPretty: '+49 30 456646543',
  fromMatches: possibleMatches,
}

// What the user create flyout asks for once opened for an unknown caller.
export const mockUserCreateFlyoutQueries = () => {
  mockObjectManagerFrontendAttributesQuery({
    objectManagerFrontendAttributes: {
      attributes: [],
      screens: [
        {
          name: 'create',
          attributes: ['firstname', 'lastname', 'email', 'phone', 'role_ids'],
        },
      ],
    },
  })

  mockFormUpdaterQuery({ formUpdater: FormUpdaterUser() })
}
