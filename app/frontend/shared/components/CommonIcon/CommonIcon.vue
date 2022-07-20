<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import type { Animations, Sizes } from './types'

export interface Props {
  size?: Sizes
  fixedSize?: { width: number; height: number }
  name: string
  decorative?: boolean
  animation?: Animations
}

const animationClassMap: Record<Animations, string> = {
  pulse: 'animate-pulse',
  spin: 'animate-spin',
  ping: 'animate-ping',
  bounce: 'animate-bounce',
}

const sizeMap: Record<Sizes, number> = {
  xs: 10,
  tiny: 15,
  small: 20,
  base: 25,
  medium: 30,
  large: 40,
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

const iconClass = computed(() => {
  let className = `icon-${props.name}`
  if (props.animation) {
    className += ` ${animationClassMap[props.animation]}`
  }
  return className
})

const finalSize = computed(() => {
  if (props.fixedSize) return props.fixedSize

  return {
    width: sizeMap[props.size],
    height: sizeMap[props.size],
  }
})
</script>

<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    class="icon fill-current"
    :class="iconClass"
    :width="finalSize.width"
    :height="finalSize.height"
    :aria-labelledby="name"
    :aria-hidden="decorative"
    @click="onClick"
  >
    <use :href="`#icon-${name}`" />
  </svg>
</template>
