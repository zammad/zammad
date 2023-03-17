<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { usePrivateIcon } from './composable'
import type { Animations, Sizes } from './types'

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
  (e: 'click', event: MouseEvent): void
}>()

const onClick = (event: MouseEvent) => {
  emit('click', event)
}

const { iconClass, finalSize } = usePrivateIcon(props)
</script>

<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    class="icon fill-current"
    :class="iconClass"
    :width="finalSize.width"
    :height="finalSize.height"
    :aria-label="decorative ? undefined : $t(label || name)"
    :aria-hidden="decorative"
    @click="onClick"
  >
    <use :href="`#icon-${name}`" />
  </svg>
</template>
