<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'

import CommonTabGroup from '#desktop/components/CommonTabGroup/CommonTabGroup.vue'

import type { FieldToggleButtonsProps } from './types.ts'

const props = defineProps<FieldToggleButtonsProps>()
const contextReactive = toRef(props, 'context')
const { localValue } = useValue<string>(contextReactive)

const tabs = computed(() => {
  return contextReactive.value.options.map((option) => {
    return {
      label: option.label,
      key: option.value,
      icon: option.icon,
      disabled: option.disabled,
    }
  })
})
</script>

<template>
  <div
    :id="context.id"
    :class="context.classes.input"
    :aria-describedby="context.describedBy"
    v-bind="context.attrs"
  >
    <CommonTabGroup v-if="tabs.length > 0" v-model="localValue" :tabs="tabs" />
  </div>
</template>
