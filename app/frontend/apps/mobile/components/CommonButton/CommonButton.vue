<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { startCase } from 'lodash-es'
import { computed } from 'vue'

import type { CommonButtonProps } from '#mobile/components/CommonButton/types.ts'

const props = withDefaults(defineProps<CommonButtonProps>(), {
  type: 'button',
  variant: 'secondary',
  size: 'medium',
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

const sizeClasses = computed(() => {
  switch (props.size) {
    case 'small':
      return ['btn-sm', 'text-sm']
    case 'medium':
    default:
      return ['btn-md', 'text-base']
  }
})

const iconSizeClass = computed(() => {
  switch (props.size) {
    case 'small':
      return 'tiny'
    case 'medium':
    default:
      return 'small'
  }
})
</script>

<template>
  <button
    :type="type"
    :form="form"
    :disabled="disabled"
    class="inline-flex flex-shrink-0 flex-nowrap items-center justify-center gap-x-1 border-0"
    :class="[
      ...transparentBackgroundClasses,
      ...variantClasses,
      ...sizeClasses,
      {
        'opacity-50': disabled,
      },
    ]"
  >
    <CommonIcon
      v-if="prefixIcon"
      class="shrink-0"
      decorative
      :size="iconSizeClass"
      :name="prefixIcon"
    />

    <CommonIcon
      v-if="icon"
      class="shrink-0"
      :size="iconSizeClass"
      decorative
      :name="icon"
    />
    <span v-else class="truncate"
      ><slot>{{ $t(startCase(variant)) }}</slot></span
    >

    <CommonIcon
      v-if="suffixIcon"
      class="shrink-0"
      decorative
      :size="iconSizeClass"
      :name="suffixIcon"
    />
  </button>
</template>
