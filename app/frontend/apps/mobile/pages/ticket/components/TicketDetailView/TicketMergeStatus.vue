<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonTicketStateIndicator from '@shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import type { AutocompleteSearchMergeTicketEntry } from '@shared/graphql/types'

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
