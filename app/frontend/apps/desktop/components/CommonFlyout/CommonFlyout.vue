<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { nextTick, onMounted, type Ref, ref, watch } from 'vue'
import {
  useWindowSize,
  useLocalStorage,
  useScroll,
  onKeyUp,
} from '@vueuse/core'

import { getFirstFocusableElement } from '#shared/utils/getFocusableElements.ts'

import ResizeHandle from '#desktop/components/ResizeHandle/ResizeHandle.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonOverlayContainer from '#desktop/components/CommonOverlayContainer/CommonOverlayContainer.vue'
import { useResizeWidthHandle } from '#desktop/components/ResizeHandle/composables/useResizeWidthHandle.ts'
import type { FlyoutSizes } from '#desktop/components/CommonFlyout/types.ts'

import stopEvent from '#shared/utils/events.ts'
import { closeFlyout } from './useFlyout.ts'

import CommonFlyoutActionFooter, {
  type Props as ActionFooterProps,
} from './CommonFlyoutActionFooter.vue'

export interface Props {
  /**
   * @property name
   * Unique name which gets used to identify the flyout
   * @example 'crop-avatar'
   */
  name: string
  /**
   * @property persistResizeWidth
   * If true, the given flyout resizable width will be stored in local storage
   * Stored under the key `flyout-${name}-width`
   * @example 'crop-avatar' => 'flyout-crop-avatar-width'
   */
  persistResizeWidth?: boolean
  headerTitle?: string
  size?: FlyoutSizes
  headerIcon?: string
  resizable?: boolean
  showBackdrop?: boolean
  closeOnBackdropClick?: boolean
  closeOnEscape?: boolean
  hideFooter?: boolean
  footerActionOptions?: ActionFooterProps
  /**
   * @property noAutofocus
   * Don't focus the first element inside a Flyout after being mounted
   * if nothing is focusable, will focus "Close" button when dismissable is active.
   */
  noAutofocus?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  resizable: true,
  showBackdrop: true,
  closeOnBackdropClick: true,
  closeOnEscape: true,
})

defineOptions({
  inheritAttrs: false,
})

const emit = defineEmits<{
  action: [void]
  close: [void]
}>()

const close = async () => {
  emit('close')
  await closeFlyout(props.name)
}

const action = async () => {
  emit('action')
  await closeFlyout(props.name)
}

const flyoutId = `flyout-${props.name}`

const flyoutSize = { medium: 500 }

// Width control over flyout
let flyoutContainerWidth: Ref<number>
const gap = 16 // Gap between sidebar and flyout

const storageKeys = Object.keys(localStorage).filter((key) =>
  key.includes('sidebar-width'),
)

const leftSideBarKey = storageKeys.find((key) => key.includes('left'))

if (props.persistResizeWidth) {
  flyoutContainerWidth = useLocalStorage(
    `${flyoutId}-width`,
    flyoutSize[props.size || 'medium'],
  )
} else {
  flyoutContainerWidth = ref(flyoutSize[props.size || 'medium'])
}

const resizeHandleComponent = ref<InstanceType<typeof ResizeHandle>>()
const { width: screenWidth } = useWindowSize()

const resizeCallback = (valueX: number) => {
  const leftSidebarWidth = leftSideBarKey
    ? Number(localStorage.getItem(leftSideBarKey))
    : 0

  // Calculate the viewport width minus the left sidebar width and a threshold gap
  const totalAllowedWidth = screenWidth.value - leftSidebarWidth - gap

  if (valueX >= totalAllowedWidth) return
  flyoutContainerWidth.value = valueX
}

const { startResizing, isResizingHorizontal } = useResizeWidthHandle(
  resizeCallback,
  resizeHandleComponent,
  {
    calculateFromRight: true,
  },
)

const resetWidth = () => {
  flyoutContainerWidth.value = flyoutSize[props.size || 'medium']
}

onMounted(async () => {
  // Prevent left sidebar to collapse with flyout
  await nextTick()

  if (!leftSideBarKey) return

  const leftSidebarWidth = useLocalStorage(leftSideBarKey, 500)

  watch(leftSidebarWidth, (newWidth, oldValue) => {
    if (newWidth + gap < screenWidth.value - flyoutContainerWidth.value) return
    resizeCallback(flyoutContainerWidth.value - (newWidth - oldValue))
  })
})

// Keyboard
onKeyUp('Escape', (e) => {
  if (!props.closeOnEscape) return
  stopEvent(e)
  close()
})

// Style
const contentElement = ref<HTMLDivElement>()
const headerElement = ref<HTMLDivElement>()
const footerElement = ref<HTMLDivElement>()

const { arrivedState } = useScroll(contentElement)

const isContentOverflowing = ref(false)

watch(
  flyoutContainerWidth,
  async () => {
    // Watch if panel gets resized to show and hide styling based on content overflow
    await nextTick()

    if (
      contentElement.value?.scrollHeight &&
      contentElement.value?.clientHeight
    ) {
      isContentOverflowing.value =
        contentElement.value.scrollHeight > contentElement.value.clientHeight
    }
  },
  { immediate: true },
)

// Focus
onMounted(() => {
  if (props.noAutofocus) return

  const firstFocusableNode =
    getFirstFocusableElement(contentElement.value) ||
    getFirstFocusableElement(footerElement.value) ||
    getFirstFocusableElement(headerElement.value)

  nextTick(() => {
    firstFocusableNode?.focus()
    firstFocusableNode?.scrollIntoView({ block: 'nearest' })
  })
})
</script>

<template>
  <CommonOverlayContainer
    :id="flyoutId"
    tag="aside"
    tabindex="-1"
    class="overflow-clip-x fixed bottom-0 top-0 z-40 flex max-h-dvh min-w-min flex-col border-y border-neutral-100 bg-white ltr:right-0 ltr:rounded-l-xl ltr:border-l rtl:left-0 rtl:rounded-r-xl rtl:border-r dark:border-gray-900 dark:bg-gray-500"
    :close-on-backdrop-click="closeOnBackdropClick"
    :show-backdrop="showBackdrop"
    :style="{ width: `${flyoutContainerWidth}px` }"
    :class="{ 'transition-all': !isResizingHorizontal }"
    :aria-label="$t('Panel')"
    :aria-labelledby="`${flyoutId}-title`"
    @click-background="close()"
  >
    <header
      ref="headerElement"
      class="sticky top-0 flex items-center border-b border-neutral-100 border-b-transparent bg-white p-3 ltr:rounded-tl-xl rtl:rounded-tr-xl dark:bg-gray-500"
      :class="{
        'border-b-neutral-100 dark:border-b-gray-900':
          !arrivedState.top && isContentOverflowing,
      }"
    >
      <slot name="header">
        <div
          class="flex items-center gap-2 text-base text-gray-100 dark:text-neutral-400"
        >
          <CommonIcon
            v-if="headerIcon"
            class="flex-shrink-0"
            size="small"
            :name="headerIcon"
          />
          <h3 v-if="headerTitle" :id="`${flyoutId}-title`">
            {{ headerTitle }}
          </h3>
        </div>
      </slot>
      <CommonButton
        class="ltr:ml-auto rtl:mr-auto"
        variant="neutral"
        size="medium"
        :aria-label="$t('Close panel')"
        icon="x-lg"
        @click="close()"
      />
    </header>

    <div
      ref="contentElement"
      class="h-full overflow-y-scroll px-3"
      v-bind="$attrs"
    >
      <slot />
    </div>

    <footer
      v-if="$slots.footer || !hideFooter"
      ref="footerElement"
      :aria-label="$t('Panel footer')"
      class="sticky bottom-0 border-t border-t-transparent bg-white p-3 ltr:rounded-bl-xl rtl:rounded-br-xl dark:bg-gray-500"
      :class="{
        'border-t-neutral-100 dark:border-t-gray-900':
          !arrivedState.bottom && isContentOverflowing,
      }"
    >
      <slot name="footer">
        <CommonFlyoutActionFooter
          v-bind="footerActionOptions"
          @cancel="close()"
          @action="action()"
        />
      </slot>
    </footer>

    <ResizeHandle
      v-if="resizable"
      ref="resizeHandleComponent"
      class="absolute top-1/2 -translate-y-1/2 ltr:left-0 rtl:right-0"
      :aria-label="$t('Resize panel')"
      role="separator"
      aria-orientation="horizontal"
      :aria-valuenow="flyoutContainerWidth"
      @mousedown="startResizing"
      @touchstart="startResizing"
      @dblclick="resetWidth()"
    />
  </CommonOverlayContainer>
</template>
