<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { SelectOption } from '#shared/components/CommonSelect/types.ts'

import CommonSelect from '#mobile/components/CommonSelect/CommonSelect.vue'

const props = defineProps<{
  modelValue?: string | number | boolean | (string | number | boolean)[] | null
  options: SelectOption[]
  placeholder?: string
  multiple?: boolean
  noClose?: boolean
  noOptionsLabelTranslation?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [string | number | (string | number)[]]
  select: [SelectOption]
}>()

const dialogProps = computed(() => {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { placeholder, ...dialogProps } = props
  return dialogProps
})

const defaultLabel = computed(() => {
  const option = props.options.find(
    (option) => option.value === props.modelValue,
  )
  return option?.label || props.placeholder || ''
})
</script>

<template>
  <CommonSelect
    #default="{ open, state: expanded }"
    v-bind="dialogProps"
    @update:model-value="emit('update:modelValue', $event)"
    @select="emit('select', $event)"
  >
    <button
      type="button"
      aria-controls="common-select"
      aria-owns="common-select"
      aria-haspopup="dialog"
      :aria-expanded="expanded"
      class="inline-flex w-auto cursor-pointer rounded-lg bg-gray-600 py-1 ltr:pl-2 ltr:pr-1 rtl:pl-1 rtl:pr-2"
      @click="open()"
      @keypress.space.prevent="open()"
    >
      <slot>
        {{ defaultLabel }}
      </slot>
      <CommonIcon
        class="self-center"
        name="caret-down"
        size="tiny"
        decorative
      />
    </button>
  </CommonSelect>
</template>
