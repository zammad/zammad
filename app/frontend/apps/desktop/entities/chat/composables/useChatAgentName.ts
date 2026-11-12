// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toValue, type MaybeRefOrGetter } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

import { formatChatAgentName, type NamedAgent } from '#desktop/entities/chat/utils.ts'

export const useChatAgentName = (agent: MaybeRefOrGetter<Maybe<NamedAgent> | undefined>) => {
  const application = useApplicationStore()

  return computed(() => {
    const namedAgent = toValue(agent)

    return namedAgent ? formatChatAgentName(namedAgent, application.config.user_name_format) : ''
  })
}
