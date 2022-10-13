<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { type Props as IconProps } from '@shared/components/CommonIcon/CommonIcon.vue'
import type { CommonButtonOption } from './types'

export interface Props {
  options: CommonButtonOption[]
}

defineProps<Props>()

const getIconProps = (option: CommonButtonOption): IconProps => {
  if (!option.icon) return {} as IconProps
  if (typeof option.icon === 'string') {
    return { name: option.icon, size: 'small' }
  }
  return option.icon
}
</script>

<template>
  <div class="flex w-full gap-3">
    <Component
      :is="option.link ? 'CommonLink' : 'button'"
      v-for="option of options"
      :key="option.label"
      :disabled="option.disabled"
      :link="option.link"
      class="flex flex-1 flex-col items-center justify-center gap-1 rounded-xl bg-gray-500 p-2 text-white"
      :class="{ 'bg-gray-200': option.selected }"
      @click="!option.disabled && option.onAction?.()"
    >
      <CommonIcon v-if="option.icon" v-bind="getIconProps(option)" decorative />
      <span>{{ $t(option.label, ...(option.labelPlaceholder || [])) }}</span>
    </Component>
  </div>
</template>
