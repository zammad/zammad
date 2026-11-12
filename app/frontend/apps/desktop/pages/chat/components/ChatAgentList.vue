<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useApplicationStore } from '#shared/stores/application.ts'

import type { ChatAgentState } from '#desktop/entities/chat/types.ts'
import { formatChatAgentName } from '#desktop/entities/chat/utils.ts'

interface Props {
  agents: ChatAgentState['availableAgents']
}

const props = defineProps<Props>()

const application = useApplicationStore()

const namedAgents = computed(() =>
  props.agents.map((agent) => ({
    agent,
    name: formatChatAgentName(agent, application.config.user_name_format),
  })),
)
</script>

<template>
  <CommonLabel v-if="!agents.length" class="px-3 py-1" size="small">
    {{ $t('No available agents') }}
  </CommonLabel>

  <ul v-else class="flex flex-col gap-2">
    <li
      v-for="{ agent, name } in namedAgents"
      :key="agent.id"
      class="flex items-center gap-2 px-3 py-1 even:bg-blue-200 even:dark:bg-gray-700"
    >
      <CommonUserAvatar :entity="agent" size="small" />
      <CommonLabel class="truncate" size="small">{{ name }}</CommonLabel>
    </li>
  </ul>
</template>
