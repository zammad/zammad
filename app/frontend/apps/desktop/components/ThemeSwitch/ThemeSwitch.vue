<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useVModel } from '@vueuse/core'
import { computed } from 'vue'

import stopEvent from '#shared/utils/events.ts'

export interface Props {
  modelValue?: string
  size?: 'medium' | 'small'
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const localValue = useVModel(props, 'modelValue', emit)

const isLight = computed(() => localValue.value === 'light')
const isDark = computed(() => localValue.value === 'dark')

const nextValue = () => {
  if (isLight.value) return 'auto'
  if (isDark.value) return 'light'
  return 'dark'
}

const cycleValue = () => {
  localValue.value = nextValue()
}

defineExpose({ cycleValue })

const updateLocalValue = (e: Event) => {
  stopEvent(e)
  cycleValue()
}

const isSmall = computed(() => props.size === 'small')

const trackSizeClasses = computed(() => {
  if (isSmall.value) return 'w-11 h-[19px]'
  return 'w-14 h-6'
})

const knobSizeClasses = computed(() => {
  if (isSmall.value) return 'w-[17px] h-[17px]'
  return 'w-[22px] h-[22px]'
})

const knobTranslateClasses = computed(() => {
  if (isLight.value) return 'ltr:translate-x-px rtl:-translate-x-px'

  if (isDark.value) {
    if (isSmall.value) return 'ltr:translate-x-[26px] rtl:-translate-x-[26px]'
    return 'ltr:translate-x-[33px] rtl:-translate-x-[33px]'
  }

  if (isSmall.value) return 'ltr:translate-x-[14px] rtl:-translate-x-[14px]'
  return 'ltr:translate-x-[17px] rtl:-translate-x-[17px]'
})

const icon = computed(() => {
  if (isLight.value) return 'sun'
  if (isDark.value) return 'moon-stars'
  return 'magic'
})

const ariaChecked = computed(() => {
  if (isLight.value) return 'false'
  if (isDark.value) return 'true'
  return 'mixed'
})
</script>

<template>
  <button
    type="button"
    role="checkbox"
    class="-:bg-stone-200 dark:-:bg-gray-500 hover:-:outline-blue-600 dark:hover:-:outline-blue-900 focus:-:outline-blue-800 hover:focus:-:outline-blue-800 dark:hover:focus:-:outline-blue-800 relative inline-flex flex-shrink-0 cursor-pointer items-center rounded-full ring-1 ring-neutral-100 transition-colors duration-200 ease-in-out hover:outline hover:outline-1 hover:outline-offset-2 focus:outline focus:outline-1 focus:outline-offset-2 dark:ring-gray-900"
    :class="[
      trackSizeClasses,
      {
        'bg-white dark:bg-white': isLight,
        'bg-blue-800 dark:bg-blue-800': isDark,
      },
    ]"
    :aria-label="$t('Dark Mode')"
    :aria-checked="ariaChecked"
    tabindex="0"
    @click="updateLocalValue"
    @keydown.space="updateLocalValue"
  >
    <div
      class="-:bg-white -:text-black pointer-events-none flex transform items-center justify-center rounded-full transition duration-200 ease-in-out"
      :class="[
        knobSizeClasses,
        knobTranslateClasses,
        {
          'bg-blue-800 text-white': isLight,
        },
      ]"
    >
      <CommonIcon :name="icon" size="xs" />
    </div>
  </button>
</template>
