<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

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
  count?: number
}

const props = defineProps<Props>()

const el = useTemplateRef('el')

const colorClasses = computed(() => {
  if (props.active)
    return `${props.tabMode ? '' : 'bg-white dark:bg-gray-200'} text-black!  dark:text-white!`

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
    class="inline-flex items-center gap-1 rounded-full px-3.5 py-1 text-base text-nowrap text-gray-100 outline-hidden transition-colors select-none focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:text-neutral-400"
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

    <CommonBadge
      v-if="count !== undefined"
      class="leading-snug font-bold"
      :class="{ 'cursor-pointer': !disabled && !active }"
      size="xs"
      rounded
    >
      {{ count }}
    </CommonBadge>
  </span>
</template>
