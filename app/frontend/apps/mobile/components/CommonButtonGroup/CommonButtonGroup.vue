<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { type Props as IconProps } from '@shared/components/CommonIcon/CommonIcon.vue'
import { useSessionStore } from '@shared/stores/session'
import { computed } from 'vue'
import type { CommonButtonOption } from './types'

export interface Props {
  modelValue?: string | number
  mode?: 'full' | 'compressed'
  controls?: string
  as?: 'tabs' | 'buttons'
  options: CommonButtonOption[]
}

const props = withDefaults(defineProps<Props>(), {
  mode: 'compressed',
  as: 'buttons',
})

const emit = defineEmits<{
  (e: 'update:modelValue', value?: string | number): void
}>()

const session = useSessionStore()

const filteredOptions = computed(() => {
  return props.options.filter(
    (option) =>
      !option.hidden &&
      (!option.permissions || session.hasPermission(option.permissions)),
  )
})

const getIconProps = (option: CommonButtonOption): IconProps => {
  if (!option.icon) return {} as IconProps
  if (typeof option.icon === 'string') {
    return { name: option.icon, size: 'small' }
  }
  return option.icon
}

const onButtonClick = (option: CommonButtonOption) => {
  if (option.disabled) return
  option.onAction?.()
  emit('update:modelValue', option.value)
}

const isTabs = computed(() => props.as === 'tabs')
</script>

<template>
  <div
    class="flex max-w-[100vw] gap-2 overflow-x-auto"
    :class="{ 'w-full': mode === 'full' }"
    :role="isTabs ? 'tablist' : undefined"
  >
    <Component
      :is="option.link ? 'CommonLink' : 'button'"
      v-for="option of filteredOptions"
      :key="option.label"
      :type="option.link ? undefined : 'button'"
      :role="isTabs ? 'tab' : undefined"
      :disabled="option.disabled"
      :link="option.link"
      class="flex flex-col items-center justify-center gap-1 rounded-xl bg-gray-500 px-3 text-sm text-white"
      :data-value="option.value"
      :class="{
        'bg-gray-600/50 text-white/30': option.disabled,
        'bg-gray-200':
          option.selected ||
          (option.value != null && modelValue === option.value),
        'flex-1 py-2': mode === 'full',
        'py-1': mode === 'compressed',
      }"
      :aria-controls="isTabs ? controls || option.controls : undefined"
      :aria-selected="isTabs ? modelValue === option.value : undefined"
      @click="onButtonClick(option)"
    >
      <CommonIcon v-if="option.icon" v-bind="getIconProps(option)" decorative />
      <span>{{ $t(option.label, ...(option.labelPlaceholder || [])) }}</span>
    </Component>
  </div>
</template>
