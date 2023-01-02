<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTrapTab } from '@shared/composables/useTrapTab'
import type { EventHandlers } from '@shared/types/utils'
import { getFirstFocusableElement } from '@shared/utils/getFocusableElements'
import { onKeyUp, usePointerSwipe } from '@vueuse/core'
import { nextTick, onMounted, ref, type Events } from 'vue'
import { closeDialog } from '@shared/composables/useDialog'
import stopEvent from '@shared/utils/events'

const props = defineProps<{
  name: string
  label?: string
  content?: string
  // don't focus the first element inside a Dialog after being mounted
  // if nothing is focusable, will focus "Done" button
  noAutofocus?: boolean
  listeners?: {
    done?: EventHandlers<Events>
  }
}>()

const emit = defineEmits<{
  (e: 'close'): void
}>()

const PX_SWIPE_CLOSE = -150

const top = ref('0')
const dialogElement = ref<HTMLElement>()
const contentElement = ref<HTMLElement>()

const close = async () => {
  emit('close')
  await closeDialog(props.name)
}

const canCloseDialog = () => {
  const currentDialog = dialogElement.value
  if (!currentDialog) {
    return false
  }
  // close dialog only if this is the last one opened
  const dialogs = document.querySelectorAll('[data-common-dialog]')
  return dialogs[dialogs.length - 1] === currentDialog
}

onKeyUp('Escape', (e) => {
  if (canCloseDialog()) {
    stopEvent(e)
    close()
  }
})

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

useTrapTab(dialogElement)

onMounted(() => {
  if (props.noAutofocus) return

  // will try to find focusable element inside dialog
  // if it won't find it, will try to find inside the header
  // most likely will find "Done" button
  const firstFocusable =
    getFirstFocusableElement(contentElement.value) ||
    getFirstFocusableElement(dialogElement.value)

  nextTick(() => {
    firstFocusable?.focus()
    firstFocusable?.scrollIntoView({ block: 'nearest' })
  })
})
</script>

<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<template>
  <div
    class="fixed inset-0 z-10 flex overflow-y-auto"
    :aria-label="$t(label || name)"
    role="dialog"
  >
    <div
      :id="`dialog-${name}`"
      ref="dialogElement"
      data-common-dialog
      class="flex h-full grow flex-col overflow-x-hidden bg-black"
      :class="{ 'transition-all duration-200 ease-linear': !isSwiping }"
      :style="{ transform: `translateY(${top})` }"
    >
      <div class="mx-4 h-2.5 shrink-0 rounded-t-xl bg-gray-150/40" />
      <div
        class="relative flex h-16 shrink-0 select-none items-center justify-center rounded-t-xl bg-gray-600/80"
      >
        <div class="absolute top-0 left-0 bottom-0 flex items-center pl-4">
          <slot name="before-label" />
        </div>
        <div
          class="grow text-center text-base font-semibold leading-[19px] text-white"
        >
          <slot name="label">
            {{ $t(label) }}
          </slot>
        </div>
        <div class="absolute top-0 right-0 bottom-0 flex items-center pr-4">
          <slot name="after-label">
            <button
              class="grow text-blue"
              tabindex="0"
              role="button"
              v-bind="listeners?.done"
              @pointerdown.stop
              @click="close()"
              @keypress.space.prevent="close()"
            >
              {{ $t('Done') }}
            </button>
          </slot>
        </div>
      </div>
      <div
        ref="contentElement"
        v-bind="$attrs"
        class="flex grow flex-col items-start overflow-y-auto bg-black text-white"
      >
        <slot>{{ content }}</slot>
      </div>
    </div>
  </div>
</template>
