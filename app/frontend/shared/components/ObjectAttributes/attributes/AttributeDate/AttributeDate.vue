<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDateTime from '@shared/components/CommonDateTime/CommonDateTime.vue'
import type { ObjectAttributeDate } from './attributeDateTypes'

defineProps<{
  attribute: ObjectAttributeDate
  value: string
}>()
</script>

<template>
  <CommonDateTime
    :date-time="value"
    :type="attribute.dataType === 'date' ? 'absolute' : 'configured'"
    :absolute-format="attribute.dataType"
  />
</template>
