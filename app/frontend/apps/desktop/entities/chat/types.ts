// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ChatAgentStateQuery, ChatSessionQuery } from '#shared/graphql/types.ts'

export type ChatAgentState = ChatAgentStateQuery['chatAgentState']

export type ChatSession = ChatAgentState['runningSessions'][number]

export type ChatTopic = ChatAgentState['topics'][number]

export type ChatConversationSession = ChatSessionQuery['chatSession']

export type ChatConversationMessage = ChatConversationSession['messages'][number]

export type ChatThreadEntry =
  | { kind: 'message'; id: string; message: ChatConversationMessage }
  | { kind: 'notice'; id: string; text: string }

// `at` is when the window learned of it: the push carries no time of its own.
export type ChatEnding = { reason: 'closed' | 'left'; name: string; at: string }
