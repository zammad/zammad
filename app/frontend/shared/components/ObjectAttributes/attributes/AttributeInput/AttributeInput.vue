<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { phoneify } from '@shared/utils/formatter'
import { computed } from 'vue'
import type { ObjectAttributeInput } from './attributeInputTypes'

const props = defineProps<{
  attribute: ObjectAttributeInput
  value: string | number
}>()

const link = computed(() => {
  const { linktemplate, type } = props.attribute.dataOption || {}
  // link is processed in common component
  if (linktemplate) return null
  const value = String(props.value)
  // app/assets/javascripts/app/index.coffee:135
  if (type === 'tel') return `tel:${phoneify(value)}`
  if (type === 'url') return value
  if (type === 'email') return `mailto:${value}`
  return ''
})
</script>

<template>
  <span v-if="!link">{{ value }}</span>
  <CommonLink
    v-else
    class="cursor-pointer text-blue"
    :external="attribute.dataOption.type !== 'url'"
    open-in-new-tab
    :link="link"
  >
    {{ value }}
  </CommonLink>
</template>
