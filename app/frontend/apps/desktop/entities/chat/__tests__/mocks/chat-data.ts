// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumChatSessionState, type ChatPreferencesQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { mockChatAgentStateQuery } from '#desktop/entities/chat/graphql/queries/chatAgentState.mocks.ts'
import { mockChatPreferencesQuery } from '#desktop/entities/chat/graphql/queries/chatPreferences.mocks.ts'
import { mockChatSessionQuery } from '#desktop/entities/chat/graphql/queries/chatSession.mocks.ts'
import type { ChatAgentState, ChatSession, ChatTopic } from '#desktop/entities/chat/types.ts'

// The topics, agents and sessions the chat specs are about, and the GraphQL answers built from
//   them. Nothing in here needs jsdom, so the browser project can use it too.

export const supportTopic: ChatTopic = {
  __typename: 'ChatTopic',
  id: convertToGraphQLId('Chat', 1),
  internalId: 1,
  name: 'Support',
  active: true,
}

export const salesTopic: ChatTopic = {
  __typename: 'ChatTopic',
  id: convertToGraphQLId('Chat', 2),
  internalId: 2,
  name: 'Sales',
  active: true,
}

export const currentAgent = {
  __typename: 'User' as const,
  id: convertToGraphQLId('User', 2),
  internalId: 2,
  firstname: 'Chat',
  lastname: 'Agent',
  fullname: 'Chat Agent',
  image: null,
  vip: false,
  outOfOffice: false,
  outOfOfficeStartAt: null,
  outOfOfficeEndAt: null,
  active: true,
}

export const colleague = {
  ...currentAgent,
  id: convertToGraphQLId('User', 3),
  internalId: 3,
  firstname: 'Other',
  lastname: 'Agent',
  fullname: 'Other Agent',
}

// The mock builder fills every field of the type, the messages the state does not
//   ask for included; an empty list keeps a long queue from generating hundreds of them.
export const chatSession = (
  internalId: number,
  overrides: Partial<ChatSession> = {},
): ChatSession =>
  ({
    __typename: 'ChatSession',
    id: convertToGraphQLId('Chat::Session', internalId),
    internalId,
    state: EnumChatSessionState.Waiting,
    name: null,
    tags: [],
    url: 'https://example.com/pricing',
    remoteIp: '203.0.113.5',
    dnsName: null,
    geoIp: {
      __typename: 'ChatSessionGeoIp',
      countryName: 'Germany',
      countryCode: 'DE',
      cityName: 'Berlin',
    },
    createdAt: '2026-11-03T11:14:00Z',
    updatedAt: '2026-11-03T11:14:00Z',
    topic: supportTopic,
    user: null,
    messages: [],
    ...overrides,
  }) as ChatSession

export const agentState = (overrides: DeepPartial<ChatAgentState> = {}) =>
  ({
    __typename: 'ChatAgentState' as const,
    active: true,
    topics: [supportTopic],
    waitingQueues: [{ __typename: 'ChatWaitingQueue' as const, topic: supportTopic, sessions: [] }],
    runningSessions: [],
    availableAgents: [currentAgent],
    seatsAvailable: 4,
    seatsTotal: 4,
    ...overrides,
  }) as ChatAgentState

export const mockAgentState = (overrides: DeepPartial<ChatAgentState> = {}) =>
  mockChatAgentStateQuery({ chatAgentState: agentState(overrides) })

export const runningSession = (internalId: number, user: ChatSession['user']) =>
  chatSession(internalId, { state: EnumChatSessionState.Running, user })

export const waitingSessions = (count: number) =>
  Array.from({ length: count }, (_, index) => chatSession(index + 1))

export const chatMessage = (
  id: number,
  content: string,
  createdAt: string,
  author: typeof currentAgent | null = null,
) => ({
  __typename: 'ChatMessage' as const,
  id: convertToGraphQLId('Chat::Message', id),
  content,
  createdAt,
  createdBy: author,
})

export const mockChatSession = (
  session: ChatSession = runningSession(1, currentAgent),
  messages: ReturnType<typeof chatMessage>[] = [],
) => mockChatSessionQuery({ chatSession: { ...session, messages } })

// Answers the conversation query of every window from the given sessions, without messages.
export const mockChatSessions = (sessions: ChatSession[]) =>
  mockChatSessionQuery(({ sessionId }) => ({
    chatSession: {
      ...(sessions.find((session) => session.id === sessionId) ??
        chatSession(getIdFromGraphQLId(String(sessionId)))),
      messages: [],
    },
  }))

export const preferencesTopic = (topic: ChatTopic, active = false, phrases: string[] = []) => ({
  __typename: 'ChatPreferencesTopic' as const,
  topic,
  active,
  phrases,
})

// The topics stay empty unless given: a generated list of them would run into the mock builder's loop guard.
export const chatPreferences = (
  overrides: DeepPartial<ChatPreferencesQuery['chatPreferences']> = {},
) => ({
  __typename: 'ChatPreferences' as const,
  maxWindows: 4,
  alternativeName: null,
  avatarEnabled: true,
  topics: [],
  hasTicketCreateAccess: true,
  ...overrides,
})

export const mockChatPreferences = (
  overrides: DeepPartial<ChatPreferencesQuery['chatPreferences']> = {},
) => mockChatPreferencesQuery({ chatPreferences: chatPreferences(overrides) })
