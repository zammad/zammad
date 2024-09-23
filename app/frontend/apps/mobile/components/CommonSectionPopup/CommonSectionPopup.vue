<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onClickOutside, onKeyUp, useVModel } from '@vueuse/core'
import { nextTick, type Ref, watch, useTemplateRef } from 'vue'

import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import stopEvent from '#shared/utils/events.ts'
import { getFirstFocusableElement } from '#shared/utils/getFocusableElements.ts'

import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'

import type { PopupItemDescriptor } from './types.ts'

export interface Props {
  messages?: PopupItemDescriptor[]
  state: boolean
  noRefocus?: boolean
  zIndex?: number
  heading?: string
  cancelLabel?: string
}

defineOptions({
  inheritAttrs: false,
})

const props = withDefaults(defineProps<Props>(), {
  cancelLabel: __('Cancel'),
})
const emit = defineEmits<{
  close: [isCancel: boolean]
  'update:state': [state: boolean]
}>()

const localState = useVModel(props, 'state', emit)

let animating = false

// separate method because eslint doesn't see that when it's reassigned in a template
const setAnimating = (value: boolean) => {
  animating = value
}

const hidePopup = (cancel = true) => {
  emit('close', cancel)
  localState.value = false
}

const onItemClick = (item: PopupItemDescriptor) => {
  if (item.onAction) item.onAction()
  if (item.type !== 'text' && !item.noHideOnSelect) {
    hidePopup(false)
  }
}

const wrapperElement = useTemplateRef('wrapper')

// ignore clicks while it's rendering
onClickOutside(wrapperElement, () => !animating && hidePopup(), {
  ignore: ['button > [data-ignore-click]'],
})
onKeyUp(
  'Escape',
  (e) => {
    if (localState.value) {
      stopEvent(e)
      hidePopup()
    }
  },
  { target: wrapperElement as Ref<EventTarget> },
)

useTrapTab(wrapperElement)

const focusFirstFocusableElementInside = async () => {
  await nextTick()
  const firstElement = getFirstFocusableElement(wrapperElement.value)
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

const getComponentNameByType = (type: PopupItemDescriptor['type']) => {
  if (type === 'link') return 'CommonLink'
  if (type === 'button') return CommonButton
  return 'div'
}

const getClassesByType = (type: PopupItemDescriptor['type']) => {
  if (type === 'text') return 'text-left pt-3 last:pb-3'
  return 'cursor-pointer h-14 items-center justify-center border-b border-gray-300 text-center last:border-0'
}
</script>

<template>
  <Teleport to="body">
    <Transition
      v-bind="transition"
      @before-enter="setAnimating(true)"
      @after-enter="setAnimating(false)"
    >
      <!-- empty @click is needed for https://stackoverflow.com/a/39712411 -->
      <div
        v-if="localState"
        class="window pb-safe-4 fixed bottom-0 top-0 flex w-screen flex-col justify-end px-4 text-white ltr:left-0 rtl:right-0"
        :class="{ 'z-20': !zIndex }"
        :style="{ zIndex }"
        role="presentation"
        tabindex="-1"
        data-test-id="popupWindow"
        @click="void 0"
        @keydown.esc="hidePopup()"
      >
        <div ref="wrapper" class="wrapper" role="alert" :aria-label="heading">
          <div v-bind="$attrs" class="flex w-full flex-col rounded-xl bg-black">
            <h1 v-if="heading" class="w-full pt-3 text-center text-lg">
              {{ heading }}
            </h1>
            <slot name="header" />
            <component
              :is="getComponentNameByType(item.type)"
              v-for="item in messages"
              :key="item.label"
              :link="item.link"
              class="flex w-full items-center px-4"
              :class="[getClassesByType(item.type), item.class]"
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
            {{ $t(cancelLabel) }}
          </CommonButton>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
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
