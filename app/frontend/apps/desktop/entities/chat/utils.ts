// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getFullname } from '#shared/utils/formatter.ts'

import type { RouteLocationNamedRaw } from 'vue-router'

export interface NamedAgent {
  firstname?: Maybe<string>
  lastname?: Maybe<string>
  fullname?: Maybe<string>
}

// An agent without `ticket.agent` may read the first and last name of colleagues, but not the
//   full name, so it is composed the way the setting `user_name_format` asks for.
export const formatChatAgentName = (agent: NamedAgent, nameFormat?: Maybe<string>) =>
  agent.fullname || getFullname(agent.firstname, agent.lastname, nameFormat)

interface TitledSession {
  name?: Maybe<string>
  internalId: number
  topic: { name: string }
}

// What the lists and the windows call a customer: nobody is known by name before an agent gives one.
export const chatSessionName = (session: TitledSession) => session.name || session.topic.name

export const chatSessionTitle = (session: TitledSession) =>
  `${chatSessionName(session)} #${session.internalId}`

// The customer is nobody the system knows: only a message of an agent has a creator.
export const isAgentMessage = (message: { createdBy?: Maybe<object> }) => Boolean(message.createdBy)

// Without a tab id the create route opens a fresh tab, so converting twice gives two tickets
//   and a form the agent left unsaved elsewhere is not touched. The form updater prefills from the id.
export const chatTicketCreateRoute = (sessionId: string): RouteLocationNamedRaw => ({
  name: 'TicketCreate',
  query: { chatSessionId: sessionId },
})
