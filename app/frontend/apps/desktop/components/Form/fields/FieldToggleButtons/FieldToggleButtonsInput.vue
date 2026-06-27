<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'

import CommonTabGroup from '#desktop/components/CommonTabs/CommonTabGroup/CommonTabGroup.vue'
import type { Tab } from '#desktop/components/CommonTabs/types.ts'

import type { FieldToggleButtonsProps } from './types.ts'

const props = defineProps<FieldToggleButtonsProps>()
const contextReactive = toRef(props, 'context')
const { localValue } = useValue<string>(contextReactive)

const tabs = computed<Tab[]>(() =>
  contextReactive.value.options.map((option) => ({
    label: option.label,
    key: option.value,
    icon: option.icon,
    disabled: option.disabled,
    tooltip: option.label,
  })),
)
</script>

<template>
  <CommonTabGroup
    v-if="tabs.length > 0"
    :id="context.id"
    v-bind="context.attrs"
    v-model="localValue"
    :class="context.classes.input"
    :aria-describedby="context.describedBy"
    :label="context.label"
    :tabs="tabs"
    :size="context.size"
  />
</template>
