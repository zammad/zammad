<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTrapTab } from '@shared/composables/useTrapTab'
import stopEvent from '@shared/utils/events'
import { getFirstFocusableElement } from '@shared/utils/getFocusableElements'
import { onClickOutside, onKeyUp, useVModel } from '@vueuse/core'
import { nextTick, type Ref, shallowRef, watch } from 'vue'
import type { PopupItem } from './types'

export interface Props {
  items?: PopupItem[]
  state: boolean
  noRefocus?: boolean
  zIndex?: number
  label?: string
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

const onItemClick = (item: PopupItem) => {
  if (item.onAction) item.onAction()
  if (!item.noHideOnSelect) {
    hidePopup(false)
  }
}

const wrapper = shallowRef<HTMLElement>()

onClickOutside(wrapper, () => hidePopup())
onKeyUp(
  'Escape',
  (e) => {
    if (localState.value) {
      stopEvent(e)
      hidePopup()
    }
  },
  { target: wrapper as Ref<EventTarget> },
)

useTrapTab(wrapper)

const focusFirstFocusableElementInside = async () => {
  await nextTick()
  const firstElement = getFirstFocusableElement(wrapper.value)
  firstElement?.focus()
  firstElement?.scrollIntoView({ block: 'nearest' })
}

let lastFocusableOutsideElement: HTMLElement | null = null

watch(
  localState,
  async (shown) => {
    if (shown) {
      lastFocusableOutsideElement = document.activeElement as HTMLElement
      // when popup is opened, focus the first focusable element (includes "Cancel" button)
      focusFirstFocusableElementInside()
      return
    }

    if (!props.noRefocus) {
      nextTick(() => lastFocusableOutsideElement?.focus())
    }
  },
  { immediate: true },
)

// Do not animate transitions in the test mode.
const transition = VITE_TEST_MODE
  ? undefined
  : {
      enterActiveClass: 'window-open',
      enterFromClass: 'window-close',
      leaveActiveClass: 'window-open',
      leaveToClass: 'window-close',
    }
</script>

<template>
  <Teleport to="body">
    <Transition v-bind="transition">
      <div
        v-if="localState"
        class="window fixed bottom-0 left-0 flex h-screen w-screen flex-col justify-end px-4 pb-4 text-white"
        :class="{ 'z-20': !zIndex }"
        :style="{ zIndex }"
        data-test-id="popupWindow"
        @keydown.esc="hidePopup()"
      >
        <div ref="wrapper" class="wrapper" role="alert" :aria-label="label">
          <div class="flex w-full flex-col rounded-xl bg-black">
            <slot name="header" />
            <component
              :is="item.link ? 'CommonLink' : 'button'"
              v-for="item in items"
              :key="item.label"
              :link="item.link"
              class="flex h-14 w-full cursor-pointer items-center justify-center border-b border-gray-300 text-center last:border-0"
              :class="item.class"
              :type="!item.link && 'button'"
              v-bind="item.attributes"
              @click="onItemClick(item)"
            >
              {{ $t(item.label) }}
            </component>
          </div>
          <button
            type="button"
            class="mt-3 flex h-14 w-full cursor-pointer items-center justify-center rounded-xl bg-black font-bold text-blue"
            @click="hidePopup()"
          >
            {{ $t('Cancel') }}
          </button>
        </div>
      </div>
    </Transition>
  </Teleport>
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
