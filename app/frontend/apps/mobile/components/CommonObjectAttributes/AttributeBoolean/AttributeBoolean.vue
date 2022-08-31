<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import type { ObjectAttributeBoolean } from './attributeBooleanTypes'

const props = defineProps<{
  attribute: ObjectAttributeBoolean
  value: boolean
}>()

const body = computed(() => {
  const { true: yes, false: no } = props.attribute.dataOption?.options || {}
  return props.value ? yes || __('yes') : no || __('no')
})
</script>

<template>
  {{ attribute.dataOption.translate ? $t(body) : body }}
</template>
