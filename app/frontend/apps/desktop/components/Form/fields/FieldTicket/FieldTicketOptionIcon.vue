<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicatorIcon/CommonTicketStateIndicatorIcon.vue'

import type { AutoCompleteTicketOption } from './types'

defineProps<{
  option: AutoCompleteTicketOption
}>()
</script>

<template>
  <CommonTicketStateIndicatorIcon
    class="ltr:mr-1.5 rtl:ml-1.5"
    :color-code="option.ticket.stateColorCode"
    :label="option.ticket.state.name"
  />
</template>
