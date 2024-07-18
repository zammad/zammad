<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'

import CommonTicketStateIndicatorIcon from '../CommonTicketStateIndicatorIcon/CommonTicketStateIndicatorIcon.vue'

export interface Props {
  colorCode: EnumTicketStateColorCode
  label: string
}

const props = defineProps<Props>()

const badgeVariant = computed(() => {
  switch (props.colorCode) {
    case EnumTicketStateColorCode.Closed:
      return 'success'
    case EnumTicketStateColorCode.Pending:
      return 'tertiary'
    case EnumTicketStateColorCode.Escalating:
      return 'danger'
    case EnumTicketStateColorCode.Open:
    default:
      return 'warning'
  }
})
</script>

<template>
  <CommonBadge :variant="badgeVariant" role="group" class="uppercase">
    <CommonTicketStateIndicatorIcon
      class="ltr:mr-1.5 rtl:ml-1.5"
      :color-code="props.colorCode"
      :label="label"
    />
    {{ $t(label) }}
  </CommonBadge>
</template>
