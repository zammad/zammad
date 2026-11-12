// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getActivePinia } from 'pinia'

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import type { ChatTopic } from '#desktop/entities/chat/types.ts'

import { currentAgent, supportTopic } from './chat-data.ts'

// The store mocks of the jsdom project; the data and the GraphQL answers are in `chat-data.ts`.
export * from './chat-data.ts'

// The user mock resets the permissions, so they always follow it.
export const mockChatAgent = ({
  selectedTopics = [supportTopic],
  permissions = ['chat.agent'],
}: { selectedTopics?: ChatTopic[]; permissions?: string[] } = {}) => {
  mockUserCurrent({
    id: currentAgent.id,
    internalId: currentAgent.internalId,
    firstname: currentAgent.firstname,
    lastname: currentAgent.lastname,
    fullname: currentAgent.fullname,
    preferences: {
      chat: {
        active: Object.fromEntries(selectedTopics.map((topic) => [String(topic.internalId), 'on'])),
      },
    },
  })
  mockPermissions(permissions)
}

export const mockChatEnabled = (chat = true) => mockApplicationConfig({ chat })

// What the logout does to the stores of the session. The application does it through the registry
//   of its own Pinia instance, which the test setup does not use.
export const disposeSessionStores = (...stores: { $id: string; $dispose: () => void }[]) => {
  const pinia = getActivePinia()

  stores.forEach((store) => {
    store.$dispose()
    delete pinia?.state.value[store.$id]
  })
}
