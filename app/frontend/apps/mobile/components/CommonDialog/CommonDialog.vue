<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { EventHandlers } from '@shared/types/utils'
import { usePointerSwipe } from '@vueuse/core'
import type { Events } from 'vue'
import { ref } from 'vue'
import { useDialogState } from './composable'

const props = defineProps<{
  name: string
  label?: string
  listeners?: {
    done?: EventHandlers<Events>
  }
}>()

defineEmits<{
  (e: 'close'): void
}>()

const PX_SWIPE_CLOSE = -150

const top = ref('0')
const dialogElement = ref<HTMLElement>()

const { close } = useDialogState(props)
const { distanceY, isSwiping } = usePointerSwipe(dialogElement, {
  onSwipe() {
    if (distanceY.value < 0) {
      const distance = Math.abs(distanceY.value)
      top.value = `${distance}px`
    } else {
      top.value = '0'
    }
  },
  onSwipeEnd() {
    if (distanceY.value <= PX_SWIPE_CLOSE) {
      close()
    } else {
      top.value = '0'
    }
  },
  pointerTypes: ['touch', 'pen'],
})
</script>

<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<template>
  <div class="fixed inset-0 z-10 flex overflow-y-auto" role="dialog">
    <div
      ref="dialogElement"
      class="flex h-full grow flex-col bg-black"
      :class="{ 'transition-all duration-200 ease-linear': !isSwiping }"
      :style="{ transform: `translateY(${top})` }"
    >
      <div class="mx-4 h-2.5 shrink-0 rounded-t-xl bg-gray-150/40" />
      <div
        class="relative flex h-16 shrink-0 select-none items-center justify-center rounded-t-xl bg-gray-600/80"
      >
        <slot name="before-label" />
        <div
          class="grow text-center text-base font-semibold leading-[19px] text-white"
        >
          <slot name="label">
            {{ i18n.t(label) }}
          </slot>
        </div>
        <slot name="after-label">
          <div class="absolute top-0 right-0 bottom-0 flex items-center pr-4">
            <div
              class="grow cursor-pointer text-blue"
              tabindex="0"
              role="button"
              v-bind="listeners?.done"
              @pointerdown.stop
              @click="close()"
              @keypress.space="close()"
            >
              {{ i18n.t('Done') }}
            </div>
          </div>
        </slot>
      </div>
      <div
        class="flex grow flex-col items-start overflow-y-auto bg-black text-white"
        v-bind="$attrs"
      >
        <slot />
      </div>
    </div>
  </div>
</template>
