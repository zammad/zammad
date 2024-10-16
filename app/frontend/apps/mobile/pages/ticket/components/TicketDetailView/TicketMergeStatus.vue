<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AutocompleteSearchTicketEntry } from '#shared/graphql/types.ts'

import CommonTicketStateIndicator from '#mobile/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'

defineProps<{
  option: AutocompleteSearchTicketEntry
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
