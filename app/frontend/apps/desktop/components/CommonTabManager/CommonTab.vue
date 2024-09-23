<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTemplateRef, computed } from 'vue'

interface Props {
  active?: boolean
  disabled?: boolean
  tabMode?: boolean
  size: 'medium' | 'large'
  label?: string
  icon?: string
  tooltip?: string
}

const props = defineProps<Props>()

const el = useTemplateRef('el')

const colorClasses = computed(() => {
  if (props.active)
    return 'bg-white text-black dark:bg-gray-200 dark:text-white'

  if (props.disabled) return 'text-stone-200 dark:text-neutral-500'

  return ''
})

const fontSizeClassMap = {
  medium: 'text-sm leading-snug',
  large: 'text-base leading-snug',
}

const iconClassMap = {
  medium: 'tiny',
  large: 'small',
} as const
</script>

<template>
  <span
    ref="el"
    v-tooltip="tooltip"
    class="-:text-gray-100 -:dark:text-neutral-400 -:transition-colors inline-flex select-none items-center gap-1 text-nowrap rounded-full px-3.5 py-1 text-base outline-none focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800"
    :class="[
      colorClasses,
      fontSizeClassMap[props.size],
      {
        'cursor-pointer': !disabled && ((tabMode && !active) || !tabMode),
      },
    ]"
    :aria-disabled="disabled"
  >
    <CommonIcon
      v-if="icon"
      :name="icon"
      :size="iconClassMap[props.size]"
      decorative
    />
    <template v-if="label">
      {{ $t(label) }}
    </template>
  </span>
</template>
