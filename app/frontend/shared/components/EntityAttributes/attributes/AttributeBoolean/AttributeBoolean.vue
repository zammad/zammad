<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { EntityAttributeProps } from '../../types.ts'
import type { EntityAttributeBoolean } from './attributeBooleanTypes.ts'

const props = defineProps<EntityAttributeProps<EntityAttributeBoolean, boolean>>()

const body = computed(() => {
  const { true: yes, false: no } = props.attribute.dataOption?.options || {}
  return props.value ? yes || __('yes') : no || __('no')
})

const translate = computed(() => {
  const { translate = true } = props.attribute.dataOption || {}
  return translate
})
</script>

<template>
  {{ translate ? $t(body) : body }}
</template>
