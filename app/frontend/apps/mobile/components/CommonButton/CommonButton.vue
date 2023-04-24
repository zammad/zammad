<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { startCase } from 'lodash-es'
import type { ButtonVariant } from '#shared/components/Form/fields/FieldButton/types.ts'

interface Props {
  form?: string
  type?: 'button' | 'reset' | 'submit'
  disabled?: boolean
  variant?: ButtonVariant
  transparentBackground?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  type: 'button',
  variant: 'secondary',
})

const transparentBackgroundClasses = computed(() => {
  if (props.transparentBackground) return ['rounded-none', 'bg-transparent']
  return ['rounded-xl']
})

const variantClasses = computed(() => {
  switch (props.variant) {
    case 'primary':
      if (props.transparentBackground) return ['text-blue']
      return ['bg-blue', 'text-white']
    case 'submit':
      if (props.transparentBackground) return ['font-semibold', 'text-yellow']
      return ['bg-yellow', 'font-semibold', 'text-black-full']
    case 'danger':
      if (props.transparentBackground) return ['text-red-bright']
      return ['bg-red-dark', 'text-red-bright']
    case 'secondary':
    default:
      if (props.transparentBackground) return ['text-white']
      return ['bg-gray-500', 'text-white']
  }
})
</script>

<template>
  <button
    :type="type"
    :form="form"
    :disabled="disabled"
    :class="[
      ...transparentBackgroundClasses,
      ...variantClasses,
      {
        'opacity-50': disabled,
      },
    ]"
    class="text-base"
  >
    <slot>{{ $t(startCase(variant)) }}</slot>
  </button>
</template>
