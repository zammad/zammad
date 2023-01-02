<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { translateOption } from '../../utils'
import type { ObjectAttributeMultiSelect } from './attributeMultiSelectTypes'

const props = defineProps<{
  attribute: ObjectAttributeMultiSelect
  value: string[]
}>()

const body = computed(() => {
  if (props.attribute.dataType === 'multi_tree_select') {
    return props.value
      .map((value) =>
        value
          .split('::')
          .map((option) => translateOption(props.attribute, option))
          .join('::'),
      )
      .join(', ')
  }
  return props.value
    .map((key) => {
      const option = props.attribute.dataOption.historical_options?.[key] ?? key
      return translateOption(props.attribute, option)
    })
    .join(', ')
})
</script>

<template>
  {{ body }}
</template>
