<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { i18n } from '@shared/i18n'
import { computed } from 'vue'
import type { ObjectAttributeDate } from './attributeDateTypes'

const props = defineProps<{
  attribute: ObjectAttributeDate
  value: string
}>()

const body = computed(() => {
  if (props.attribute.dataType === 'date') {
    return i18n.date(props.value)
  }
  return i18n.dateTime(props.value)
})
</script>

<template>
  {{ body }}
</template>
