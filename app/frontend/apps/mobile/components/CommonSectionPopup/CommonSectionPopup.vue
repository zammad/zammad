<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTrapTab } from '@shared/composables/useTrapTab'
import stopEvent from '@shared/utils/events'
import { getFirstFocusableElement } from '@shared/utils/getFocusableElements'
import { onClickOutside, onKeyUp, useVModel } from '@vueuse/core'
import { nextTick, type Ref, shallowRef, watch } from 'vue'
import CommonButton from '@mobile/components/CommonButton/CommonButton.vue'
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
      <!-- empty @click is needed for https://stackoverflow.com/a/39712411 -->
      <div
        v-if="localState"
        class="window fixed bottom-0 top-0 flex w-screen flex-col justify-end px-4 text-white pb-safe-4 ltr:left-0 rtl:right-0"
        :class="{ 'z-20': !zIndex }"
        :style="{ zIndex }"
        data-test-id="popupWindow"
        @click="void 0"
        @keydown.esc="hidePopup()"
      >
        <div ref="wrapper" class="wrapper" role="alert" :aria-label="label">
          <div class="flex w-full flex-col rounded-xl bg-black">
            <slot name="header" />
            <component
              :is="item.link ? 'CommonLink' : CommonButton"
              v-for="item in items"
              :key="item.label"
              :link="item.link"
              class="flex h-14 w-full cursor-pointer items-center justify-center border-b border-gray-300 text-center last:border-0"
              :class="item.class"
              :variant="!item.link && item.buttonVariant"
              :transparent-background="!item.link"
              v-bind="item.attributes"
              @click="onItemClick(item)"
            >
              {{ $t(item.label) }}
            </component>
          </div>
          <CommonButton
            class="mt-3 flex h-14 w-full items-center justify-center !bg-black"
            @click="hidePopup()"
          >
            {{ $t('Cancel') }}
          </CommonButton>
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
