<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'

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

const circleIcon = computed(() => {
  switch (props.colorCode) {
    case EnumTicketStateColorCode.Closed:
      return 'check-circle-outline'
    case EnumTicketStateColorCode.Pending:
      return 'check-circle-outline-dashed'
    case EnumTicketStateColorCode.Escalating:
    case EnumTicketStateColorCode.Open:
    default:
      return 'check-circle-no'
  }
})
</script>

<template>
  <CommonBadge :variant="badgeVariant" role="group" class="uppercase">
    <CommonIcon
      size="xs"
      :label="$t('(state: %s)', $t(label))"
      :name="circleIcon"
      class="ltr:mr-1.5 rtl:ml-1.5"
    />
    {{ $t(label) }}
  </CommonBadge>
</template>
