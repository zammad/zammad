<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEventListener } from '@vueuse/core'
import { ref, computed, watchEffect, toRef } from 'vue'

interface Props {
  articlesElement?: HTMLElement
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'load'): void
}>()

const articlesElement = toRef(props, 'articlesElement')

const isMoving = ref(false)
const startPoint = ref(0)
const differenceY = ref(0)
const loaderShown = ref(false)
const arrowShown = ref(false)

const stopLoader = () => {
  loaderShown.value = false
  arrowShown.value = false
}

defineExpose({ stopLoader })

// don't start moving untill the user has moved the mouse at least 10px
const MIN_PULL_LENGTH = 10
// start loading if the end position is at least 80px away from the start position
const MAX_PULL_LENGTH = 80

const rotateDegree = computed(() => {
  return (differenceY.value / MAX_PULL_LENGTH) * 180
})

useEventListener(articlesElement, 'touchstart', (event: TouchEvent) => {
  if (loaderShown.value) return
  startPoint.value = event.touches[0].clientY
  isMoving.value = true
  differenceY.value = 0
})
useEventListener(articlesElement, 'touchend', () => {
  if (differenceY.value === MAX_PULL_LENGTH) {
    loaderShown.value = true
    setTimeout(() => {
      window.scrollTo({
        behavior: 'smooth',
        left: 0,
        top: document.documentElement.scrollHeight,
      })
    })
    emit('load')
  }
  isMoving.value = false
  arrowShown.value = false
  differenceY.value = 0
  startPoint.value = 0
})
useEventListener(articlesElement, 'touchmove', async (event: TouchEvent) => {
  const page = document.documentElement
  const isBottom = page.scrollHeight - page.scrollTop <= page.clientHeight
  if (isBottom) {
    arrowShown.value = true
    const difference = event.touches[0].clientY - startPoint.value
    if (difference >= -MIN_PULL_LENGTH) {
      differenceY.value = 0
      return
    }
    differenceY.value = Math.min(Math.abs(difference), MAX_PULL_LENGTH)
  }
})

watchEffect(() => {
  const parent = articlesElement.value?.parentElement
  if (parent) {
    parent.style.transform = `translateY(-${differenceY.value}px)`
    parent.style.transition = 'transform 0.4s'
    // don't select text when pulling
    if (differenceY.value > 0) {
      parent.style.userSelect = 'none'
    } else {
      parent.style.userSelect = ''
    }
  }
})
</script>

<template>
  <div
    class="flex h-0 items-center justify-center"
    :class="{ invisible: !arrowShown }"
  >
    <CommonIcon
      name="mobile-arrow-down"
      size="small"
      :style="{
        transform: `translateY(22px)${
          rotateDegree ? ` rotate(${rotateDegree}deg)` : ''
        }`,
        transition: !rotateDegree ? 'transform 0.2s' : '',
      }"
    />
  </div>
  <div v-if="loaderShown" class="flex items-center justify-center">
    <CommonIcon name="mobile-loading" animation="spin" />
  </div>
</template>
