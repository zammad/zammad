<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onClickOutside, onKeyUp, useVModel } from '@vueuse/core'
import { shallowRef } from 'vue'
import type { PopupItem } from './types'

export interface Props {
  items: PopupItem[]
  state: boolean
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'close', isCancel: boolean): void
  (e: 'update:state', state: boolean): void
}>()

const localState = useVModel(props, 'state', emit)

const hidePopup = (cancel = true) => {
  emit('close', cancel)
  localState.value = false
}

const onItemClick = (action: PopupItem['onAction']) => {
  if (action) action()
  hidePopup(false)
}

const wrapper = shallowRef<HTMLElement>()

onClickOutside(wrapper, () => hidePopup())
onKeyUp(['Escape', 'Spacebar', ' '], (e) => {
  if (localState.value) {
    e.preventDefault()
    hidePopup()
  }
})
</script>

<template>
  <teleport to="body">
    <transition
      leave-active-class="window-open"
      enter-active-class="window-open"
      enter-from-class="window-close"
      leave-to-class="window-close"
    >
      <div
        v-if="localState"
        class="window fixed bottom-0 left-0 z-20 flex h-screen w-screen flex-col justify-end px-4 pb-4 text-white"
        data-test-id="popupWindow"
        @keydown.esc="hidePopup()"
      >
        <div ref="wrapper" class="wrapper">
          <div class="flex w-full flex-col rounded-xl bg-black">
            <slot name="header" />
            <component
              :is="item.link ? 'CommonLink' : 'button'"
              v-for="item in items"
              :key="item.label"
              :link="item.link"
              class="flex h-14 w-full cursor-pointer items-center justify-center border-b border-gray-300 last:border-0"
              :class="item.class"
              @click="onItemClick(item.onAction)"
            >
              {{ $t(item.label) }}
            </component>
          </div>
          <div
            class="mt-3 flex h-14 cursor-pointer items-center justify-center rounded-xl bg-black font-bold text-blue"
            @click="hidePopup()"
          >
            {{ $t('Cancel') }}
          </div>
        </div>
      </div>
    </transition>
  </teleport>
</template>

<style scoped lang="scss">
.window-open {
  &.window {
    transition: opacity 0.2s ease-in;
  }

  .wrapper {
    transition: transform 0.2s ease-in;
  }
}

.window-close {
  &.window {
    opacity: 0;
  }

  .wrapper {
    transform: translateY(100%);
  }
}

.window {
  background: hsla(0, 0%, 20%, 0.8);
}
</style>
