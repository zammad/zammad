<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import log from '#shared/utils/log.ts'

import { useIcons } from './useIcons.ts'
import { usePrivateIcon } from './usePrivateIcon.ts'

import type { Animations, Sizes } from './types.ts'

export interface Props {
  size?: Sizes
  fixedSize?: { width: number; height: number }
  name: string
  label?: string
  decorative?: boolean
  animation?: Animations
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
  decorative: false,
})

const emit = defineEmits<{
  click: [MouseEvent]
}>()

const onClick = (event: MouseEvent) => {
  emit('click', event)
}

const { iconClass, finalSize } = usePrivateIcon(props)
const { icons, aliases } = useIcons()

const iconName = computed(() => {
  const alias = aliases[props.name]
  const name = alias || props.name
  if (!icons[name]) {
    log.warn(`Icon ${name} not found`)
  }
  return name
})
</script>

<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    class="icon fill-current"
    :class="iconClass"
    :width="finalSize.width"
    :height="finalSize.height"
    :aria-label="decorative ? undefined : $t(label || iconName)"
    :aria-hidden="decorative"
    @click="onClick"
  >
    <use :href="`#icon-${iconName}`" />
  </svg>
</template>
