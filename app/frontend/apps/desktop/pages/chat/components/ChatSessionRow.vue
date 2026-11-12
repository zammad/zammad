<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { EnumChatSessionState } from '#shared/graphql/types.ts'

import { useChatAgentName } from '#desktop/entities/chat/composables/useChatAgentName.ts'
import type { ChatSession } from '#desktop/entities/chat/types.ts'
import { chatSessionTitle } from '#desktop/entities/chat/utils.ts'

interface Props {
  session: ChatSession
  showAgent?: boolean
}

const props = defineProps<Props>()

const title = computed(() => chatSessionTitle(props.session))

const agentName = useChatAgentName(() => props.session.user)

const agentLabel = computed(() =>
  props.session.state === EnumChatSessionState.Waiting ? __('Transferred from') : __('Agent'),
)

// The city leads and is there only where a GeoIP backend knows it.
const location = computed(() =>
  [props.session.geoIp?.cityName, props.session.geoIp?.countryName].filter(Boolean).join(', '),
)
</script>

<template>
  <li class="col-span-full grid grid-cols-subgrid py-2 even:bg-blue-200 even:dark:bg-gray-700">
    <CommonLabel class="max-w-40 min-w-32 px-3 text-muted!" size="small">
      <span v-tooltip.truncate.supportive="title" class="truncate">{{ title }}</span>
    </CommonLabel>

    <div
      class="flex min-w-40 items-center gap-2 border-s border-neutral-100 px-3 text-xs whitespace-nowrap dark:border-gray-900"
    >
      <CommonDateTime :date-time="session.createdAt" class="text-muted!" />
      <CommonLabel v-if="location" class="gap-1 text-muted!" size="small" suffix-icon="globe">{{
        location
      }}</CommonLabel>
    </div>

    <div
      v-if="showAgent && session.user"
      class="flex min-w-44 flex-col justify-center gap-1 border-s border-neutral-100 px-3 dark:border-gray-900"
    >
      <CommonLabel size="xs" class="text-muted!">{{ $t(agentLabel) }}</CommonLabel>
      <div class="flex items-center gap-2">
        <CommonUserAvatar :entity="session.user" size="small" />
        <CommonLabel size="small" class="max-w-40">
          <span v-tooltip.truncate.supportive="agentName" class="truncate">{{ agentName }}</span>
        </CommonLabel>
      </div>
    </div>
  </li>
</template>
