<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'

import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicatorIcon.vue'

import type { QuickSearchPluginProps } from '../../types.ts'

const props = defineProps<QuickSearchPluginProps>()

const itemLabel = computed(() => {
  if (props.mode === 'recently-viewed') {
    return (props.item as TicketById).title
  }

  return `#${props.item.number} - ${props.item.title}`
})
</script>

<template>
  <CommonLink
    class="group/item flex grow gap-2 rounded-md px-2 py-3 hover:bg-blue-900 hover:no-underline!"
    :link="`/tickets/${item.internalId}`"
    internal
  >
    <CommonTicketStateIndicatorIcon
      class="shrink-0"
      icon-size="small"
      :color-code="(item as TicketById).stateColorCode"
      :label="(item as TicketById).state.name"
    />
    <CommonLabel class="block! truncate group-hover/item:text-white">
      {{ itemLabel }}
    </CommonLabel>
  </CommonLink>
</template>
