<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSelect from '#mobile/components/CommonSelect/CommonSelect.vue'
import { computed } from 'vue'
import type { SelectOption } from '#shared/components/CommonSelect/types.ts'

const props = defineProps<{
  modelValue?: string | number | boolean | (string | number | boolean)[] | null
  options: SelectOption[]
  placeholder?: string
  multiple?: boolean
  noClose?: boolean
  noOptionsLabelTranslation?: boolean
}>()

const emit = defineEmits<{
  (
    event: 'update:modelValue',
    value: string | number | (string | number)[],
  ): void
  (e: 'select', option: SelectOption): void
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
        name="mobile-caret-down"
        size="tiny"
        decorative
      />
    </button>
  </CommonSelect>
</template>
