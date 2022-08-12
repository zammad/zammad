<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useVModel } from '@vueuse/core'
import type { ButtonPillOption } from './types'

interface Props {
  modelValue?: string | number
  options: ButtonPillOption[]
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'update:modelValue', value: string | number): void
}>()
const localValue = useVModel(props, 'modelValue', emit)
</script>

<template>
  <div
    class="flex max-w-[100vw] overflow-x-auto border-b border-white/10 px-4 pb-4"
    data-test-id="buttonPills"
  >
    <button
      v-for="option in options"
      :key="option.value"
      :disabled="option.disabled"
      class="rounded-xl py-2 px-3 text-base ltr:mr-2 rtl:ml-2"
      :class="{
        ['bg-gray-600/50 text-white/30']: option.disabled,
        ['bg-gray-200']: !option.disabled && modelValue === option.value,
        ['bg-gray-600 text-white/60']:
          !option.disabled && modelValue !== option.value,
      }"
      @click="localValue = option.value"
      @keydown.space="localValue = option.value"
    >
      {{ $t(option.label, ...(option.labelPlaceholder || [])) }}
    </button>
  </div>
</template>
