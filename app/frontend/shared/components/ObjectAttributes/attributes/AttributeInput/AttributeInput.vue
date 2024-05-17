<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
// TODO: check external data input output
import { computed } from 'vue'

import { phoneify } from '#shared/utils/formatter.ts'

import type { ObjectAttributeInput } from './attributeInputTypes.ts'

const props = defineProps<{
  attribute: ObjectAttributeInput
  value: string | number | { value: string | number; label: string }
}>()

const primitiveValue = computed(() => {
  if (typeof props.value === 'object' && props.value) return props.value.value
  return props.value
})

const title = computed(() => {
  if (typeof props.value === 'object' && props.value) return props.value.label
  return props.value
})

const link = computed(() => {
  const { linktemplate, type } = props.attribute.dataOption || {}
  // link is processed in common component
  if (linktemplate) return null
  const value = String(primitiveValue.value)
  // app/assets/javascripts/app/index.coffee:135
  if (type === 'tel') return `tel:${phoneify(value)}`
  if (type === 'url') return value
  if (type === 'email') return `mailto:${value}`
  return ''
})
</script>

<template>
  <span v-if="!link">{{ title }}</span>
  <CommonLink
    v-else
    class="text-blue cursor-pointer"
    :external="attribute.dataOption.type !== 'url'"
    open-in-new-tab
    :link="link"
  >
    {{ title }}
  </CommonLink>
</template>
