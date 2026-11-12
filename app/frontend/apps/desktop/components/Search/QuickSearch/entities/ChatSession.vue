<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { ChatSession } from '#shared/graphql/types.ts'

import type { QuickSearchPluginProps } from '../../types.ts'

const props = defineProps<QuickSearchPluginProps>()

const session = computed(() => props.item as ChatSession)

// The row of the old UI: the number identifies the session, the name an agent gave it follows.
const label = computed(() =>
  session.value.name
    ? `#${session.value.internalId} ${session.value.name}`
    : `#${session.value.internalId}`,
)
</script>

<template>
  <CommonLink
    class="group/item flex grow items-center gap-2 rounded-md px-2 py-3 text-neutral-400 hover:bg-blue-900 hover:no-underline!"
    :link="`/chat/session/${session.internalId}`"
    internal
  >
    <CommonIcon class="shrink-0 text-neutral-500" name="chat" size="tiny" decorative />
    <CommonLabel class="block! truncate group-hover/item:text-white">
      {{ label }}
    </CommonLabel>
  </CommonLink>
</template>
