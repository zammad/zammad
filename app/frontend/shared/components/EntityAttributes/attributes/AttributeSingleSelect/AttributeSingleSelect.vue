<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { translateOption } from '../../utils.ts'

import type { EntityAttributeProps } from '../../types.ts'
import type { EntityAttributeSingleSelect } from './attributeSingleSelectTypes.ts'

const props = defineProps<EntityAttributeProps<EntityAttributeSingleSelect, string>>()

const body = computed(() => {
  if (props.attribute.dataType === 'tree_select') {
    return props.value
      .split('::')
      .map((field) => translateOption(props.attribute, field))
      .join(' › ')
  }
  const value = props.attribute.dataOption.historical_options?.[props.value] ?? props.value
  return translateOption(props.attribute, value)
})
</script>

<template>
  {{ body }}
</template>
