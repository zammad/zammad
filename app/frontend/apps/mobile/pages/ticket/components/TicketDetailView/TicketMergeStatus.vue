<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AutocompleteSearchMergeTicketEntry } from '#shared/graphql/types.ts'

import CommonTicketStateIndicator from '#mobile/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'

defineProps<{
  option: AutocompleteSearchMergeTicketEntry
}>()
</script>

<template>
  <div class="ltr:pr-3 rtl:pl-3">
    <CommonTicketStateIndicator
      :color-code="option.ticket.stateColorCode"
      :label="option.ticket.state.name"
    />
  </div>
</template>
