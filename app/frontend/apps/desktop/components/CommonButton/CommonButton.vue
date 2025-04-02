<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { startCase } from 'lodash-es'
import { computed } from 'vue'

import type { ButtonSize, ButtonType, ButtonVariant } from './types.ts'

export interface Props {
  variant?: ButtonVariant
  type?: ButtonType
  disabled?: boolean
  block?: boolean
  form?: string
  size?: ButtonSize
  prefixIcon?: string
  icon?: string
  suffixIcon?: string
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'secondary',
  type: 'button',
  size: 'small',
})

const variantClasses = computed(() => {
  switch (props.variant) {
    case 'primary':
      return ['bg-blue-800', 'hover:bg-blue-800', 'text-white']
    case 'tertiary':
      return [
        'bg-green-200',
        'hover:bg-green-200',
        'dark:bg-gray-600',
        'dark:hover:bg-gray-600',
        'text-gray-300',
        'dark:text-neutral-400',
      ]
    case 'submit':
      return ['bg-yellow-300', 'hover:bg-yellow-300', 'text-black']
    case 'danger':
      return [
        'bg-pink-100',
        'hover:bg-pink-100',
        'dark:bg-red-900',
        'dark:hover:bg-red-900',
        'text-red-500',
      ]
    case 'remove':
      return [
        'bg-red-400',
        'hover:bg-red-400',
        'dark:bg-red-600',
        'dark:hover:bg-red-600',
        'text-white',
      ]
    case 'subtle':
      return [
        'bg-blue-600',
        'dark:bg-blue-900',
        'hover:bg-blue-600',
        'dark:hover:bg-blue-900',
        'text-black',
        'dark:text-white',
      ]
    case 'neutral':
      return [
        'bg-transparent',
        'hover:bg-transparent',
        'text-gray-100',
        'dark:text-neutral-400',
      ]
    case 'none':
      return []
    case 'secondary':
    default:
      return ['bg-transparent', 'hover:bg-transparent', 'text-blue-800']
  }
})

const sizeClasses = computed(() => {
  switch (props.size) {
    case 'large':
      return ['btn-lg', 'text-base']
    case 'medium':
      return ['btn-md', 'text-sm']
    case 'small':
    default:
      return ['btn-sm', 'text-xs']
  }
})

const paddingClasses = computed(() => {
  if (props.size === 'large' && props.icon) return ['p-2']

  if (props.icon) return ['p-1']

  switch (props.size) {
    case 'large':
      return ['px-4', 'py-2.5']
    case 'medium':
      return ['px-3', 'py-2']
    case 'small':
    default:
      return ['px-2.5', 'py-1.5']
  }
})

const disabledClasses = computed(() => {
  if (!props.disabled) return []

  return ['opacity-30', 'pointer-events-none']
})

const borderRadiusClass = computed(() => {
  switch (props.size) {
    case 'large':
      if (props.icon) return 'rounded-lg'
      return 'rounded-xl'
    case 'medium':
      return 'rounded-lg'
    case 'small':
    default:
      return 'rounded-md'
  }
})

const iconSizeClass = computed(() => {
  switch (props.size) {
    case 'large':
      return 'small'
    case 'medium':
      return 'tiny'
    case 'small':
    default:
      return 'xs'
  }
})
</script>

<template>
  <button
    class="inline-flex h-min min-h-min flex-shrink-0 flex-nowrap items-center justify-center gap-x-1 border-0 font-normal shadow-none transition-transform duration-200 hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 focus:outline-hidden focus:outline-0 focus:outline-offset-0 focus:hover:outline-1 focus:hover:outline-offset-1 focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 focus:active:scale-[95%] focus:active:outline-blue-800! dark:hover:outline-blue-900"
    :class="[
      ...variantClasses,
      ...sizeClasses,
      ...paddingClasses,
      ...disabledClasses,
      borderRadiusClass,
      {
        'w-full': block,
        'w-min': !block,
      },
    ]"
    :type="type"
    :form="form"
    :tabindex="disabled ? '-1' : '0'"
    :aria-disabled="disabled ? 'true' : undefined"
  >
    <slot name="label">
      <CommonIcon
        v-if="prefixIcon"
        class="pointer-events-none shrink-0"
        decorative
        :size="iconSizeClass"
        :name="prefixIcon"
      />

      <CommonIcon
        v-if="icon"
        class="pointer-events-none block shrink-0"
        decorative
        :size="iconSizeClass"
        :name="icon"
      />
      <span v-else class="truncate">
        <slot>{{ $t(startCase(variant)) }}</slot>
      </span>

      <CommonIcon
        v-if="suffixIcon"
        class="pointer-events-none shrink-0"
        decorative
        :size="iconSizeClass"
        :name="suffixIcon"
      />
    </slot>
  </button>
</template>
