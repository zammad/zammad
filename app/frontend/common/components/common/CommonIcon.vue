<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    class="fill-current icon"
    v-bind:class="iconClass"
    v-bind:width="finalSize.width"
    v-bind:height="finalSize.height"
    v-bind:aria-labelledby="name"
    v-bind:aria-hidden="decorative"
    v-on:click="onClick"
  >
    <use v-bind:xlink:href="`#icon-${name}`" />
  </svg>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const animationClassMap = {
  pulse: 'animate-pulse',
  spin: 'animate-spin',
  ping: 'animate-ping',
  bounce: 'animate-bounce',
} as const

type Animations = keyof typeof animationClassMap

const sizeMap = {
  small: 20,
  medium: 30,
  large: 40,
} as const

type Sizes = keyof typeof sizeMap

interface Props {
  size?: Sizes
  fixedSize?: { width: number; height: number }
  name: string
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
