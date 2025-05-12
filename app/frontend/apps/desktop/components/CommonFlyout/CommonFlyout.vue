<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  useWindowSize,
  useLocalStorage,
  useScroll,
  useActiveElement,
  useCurrentElement,
  type MaybeElementRef,
  type ComputedRefWithControl,
  type VueInstance,
} from '@vueuse/core'
import { whenever } from '@vueuse/shared'
import {
  computed,
  nextTick,
  useTemplateRef,
  onMounted,
  type Ref,
  ref,
  shallowRef,
  watch,
  toRef,
} from 'vue'
import { useRoute, useRouter } from 'vue-router'

import type { FormRef } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { getFirstFocusableElement } from '#shared/utils/getFocusableElements.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonOverlayContainer from '#desktop/components/CommonOverlayContainer/CommonOverlayContainer.vue'
import ResizeLine from '#desktop/components/ResizeLine/ResizeLine.vue'
import { useResizeLine } from '#desktop/components/ResizeLine/useResizeLine.ts'
import {
  type OrderKeyHandlerConfig,
  KeyboardKey,
} from '#desktop/composables/useOrderedKeyboardEvents/types.ts'
import { useKeyboardEventBus } from '#desktop/composables/useOrderedKeyboardEvents/useKeyboardEventBus.ts'
import { getRouteIdentifier } from '#desktop/composables/useOverlayContainer.ts'

import CommonFlyoutActionFooter from './CommonFlyoutActionFooter.vue'
import { closeFlyout } from './useFlyout.ts'

import type { ActionFooterOptions, FlyoutSizes } from './types.ts'

export interface Props {
  /**
   * Unique name which gets used to identify the flyout
   * @example 'crop-avatar'
   */
  name: string
  /**
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
  noCloseOnBackdropClick?: boolean
  noCloseOnEscape?: boolean
  hideFooter?: boolean
  form?: FormRef
  footerActionOptions?: ActionFooterOptions
  noCloseOnAction?: boolean
  /**
   * Don't focus the first element inside a Flyout after being mounted
   * if nothing is focusable, will focus the "Close" button when dismissible is active.
   */
  noAutofocus?: boolean
  fullscreen?: boolean
  /**
   * If true, no page context will be added to the name, e.g. for confirmation dialogs.
   */
  global?: boolean
  /**
   */
  escapeConfig?: Pick<OrderKeyHandlerConfig, 'beforeHandlerRuns' | 'handler'>
}

const props = withDefaults(defineProps<Props>(), {
  resizable: true,
  showBackdrop: true,
})

defineOptions({
  inheritAttrs: false,
})

const emit = defineEmits<{
  action: []
  close: [boolean?]
  activated: []
}>()

const routeIdentifier = getRouteIdentifier(useRoute())

const router = useRouter()

const isActive = computed(() =>
  props.fullscreen
    ? true
    : routeIdentifier === getRouteIdentifier(router.currentRoute.value),
)

whenever(isActive, () => {
  emit('activated')
})

const {
  isDirty: isFormDirty,
  isDisabled: isFormDisabled,
  formNodeId,
} = useForm(toRef(props, 'form'))

const { waitForVariantConfirmation } = useConfirmation()

const close = async (isCancel?: boolean) => {
  if (props.form && isFormDirty.value) {
    let dialogName = `flyout-unsaved-${props.name}`

    if (!props.global) {
      dialogName = `${dialogName}_${routeIdentifier}`
    }

    const confirmed = await waitForVariantConfirmation(
      'unsaved',
      undefined,
      dialogName,
    )

    if (!confirmed) return
  }

  emit('close', isCancel)

  await closeFlyout(props.name, props.global)
}

// TODO: maybe we could add a better handling in combination with a form....
const action = async () => {
  emit('action')

  if (props.noCloseOnAction) return

  await closeFlyout(props.name, props.global)
}

const flyoutId = `flyout-${props.name}`

const flyoutSize = { medium: 500, large: 800 }

const overlayInstance = useTemplateRef('flyout-container')

// :TODO: seems to not be typed correctly inside the library
const flyoutContainerElement = useCurrentElement(
  overlayInstance as MaybeElementRef<VueInstance> | undefined,
)

useTrapTab(flyoutContainerElement as ComputedRefWithControl<HTMLElement>)

// Width control over flyout
let flyoutContainerWidth: Ref<number>

const gap = 16 // Gap between sidebar and flyout

const storageKeys = Object.keys(localStorage).filter((key) =>
  key.includes('sidebar-width'),
)

const leftSideBarKey = storageKeys.find((key) => key.includes('left'))

const leftSidebarWidth = leftSideBarKey
  ? useLocalStorage(leftSideBarKey, 0)
  : shallowRef(0)

const { width: screenWidth } = useWindowSize()
// Calculate the viewport width minus the left sidebar width and a threshold gap
const flyoutMaxWidth = computed(
  () => screenWidth.value - leftSidebarWidth.value - gap,
)

if (props.persistResizeWidth) {
  flyoutContainerWidth = useLocalStorage(
    `${flyoutId}-width`,
    flyoutSize[props.size || 'medium'],
  )
} else {
  flyoutContainerWidth = ref(flyoutSize[props.size || 'medium'])
}

const resizeHandleInstance = useTemplateRef('resize-handle')

const resizeCallback = (valueX: number) => {
  if (valueX >= flyoutMaxWidth.value) return
  flyoutContainerWidth.value = valueX
}

// a11y keyboard navigation
const activeElement = useActiveElement()

const handleKeyStroke = (e: KeyboardEvent, adjustment: number) => {
  if (
    !flyoutContainerWidth.value ||
    activeElement.value !== resizeHandleInstance.value?.resizeLine
  )
    return

  e.preventDefault()

  const newWidth = flyoutContainerWidth.value + adjustment

  if (newWidth >= flyoutMaxWidth.value) return

  resizeCallback(newWidth)
}

const { startResizing, isResizing } = useResizeLine(
  resizeCallback,
  resizeHandleInstance.value?.resizeLine,
  handleKeyStroke,
  {
    calculateFromRight: true,
    orientation: 'vertical',
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

const escapeHandler = () => {
  if (props.noCloseOnEscape) return
  close()
}

const escapeConfig: OrderKeyHandlerConfig = {
  handler: () => {
    if (props.escapeConfig?.handler) props.escapeConfig.handler()
    escapeHandler()
  },
  key: flyoutId,
  beforeHandlerRuns: props.escapeConfig?.beforeHandlerRuns,
}

const { subscribeEvent, unsubscribeEvent } = useKeyboardEventBus(
  KeyboardKey.Escape,
  escapeConfig,
)

watch(isActive, (isActive) =>
  isActive ? subscribeEvent(escapeConfig) : unsubscribeEvent(escapeConfig),
)

// Style
const contentElement = useTemplateRef('content')
const headerElement = useTemplateRef('header')
const footerElement = useTemplateRef('footer')

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

// It is the same as dialog, but could be changed in the future?
const transition = VITE_TEST_MODE
  ? undefined
  : {
      enterActiveClass: 'duration-300 ease-out',
      enterFromClass: 'opacity-0 rtl:-translate-x-3/4 ltr:translate-x-3/4',
      enterToClass: 'opacity-100 rtl:-translate-x-0 ltr:translate-x-0',
      leaveActiveClass: 'duration-200 ease-in',
      leaveFromClass: 'opacity-100 rtl:-translate-x-0 ltr:translate-x-0',
      leaveToClass: 'opacity-0 rtl:-translate-x-3/4 ltr:translate-x-3/4',
    }
</script>

<template>
  <Transition :appear="isActive" v-bind="transition">
    <!--  `display:none` to prevent showing up inactive flyout for cached instance -->
    <CommonOverlayContainer
      :id="flyoutId"
      ref="flyout-container"
      tag="aside"
      tabindex="-1"
      class="overflow-clip-x fixed top-0 bottom-0 z-40 flex max-h-dvh min-w-min flex-col border-y border-neutral-100 bg-neutral-50 ltr:right-0 ltr:rounded-l-xl ltr:border-l rtl:left-0 rtl:rounded-r-xl rtl:border-r dark:border-gray-900 dark:bg-gray-500"
      :no-close-on-backdrop-click="noCloseOnBackdropClick"
      :show-backdrop="showBackdrop && isActive"
      :style="{ width: `${flyoutContainerWidth}px` }"
      :class="{ 'transition-all': !isResizing, hidden: !isActive }"
      :fullscreen="fullscreen"
      :aria-labelledby="`${flyoutId}-title`"
      @click-background="close()"
    >
      <header
        ref="header"
        class="sticky top-0 flex items-center border-b border-neutral-100 border-b-transparent bg-neutral-50 p-3 ltr:rounded-tl-xl rtl:rounded-tr-xl dark:bg-gray-500"
        :class="{
          'border-b-neutral-100 dark:border-b-gray-900':
            !arrivedState.top && isContentOverflowing,
        }"
      >
        <slot name="header">
          <CommonLabel
            v-if="headerTitle"
            :id="`${flyoutId}-title`"
            tag="h2"
            class="min-h-7 grow gap-1.5"
            size="large"
            :prefix-icon="headerIcon"
            icon-color="text-stone-200 dark:text-neutral-500"
          >
            {{ $t(headerTitle) }}
          </CommonLabel>
        </slot>
        <CommonButton
          class="ltr:ml-auto rtl:mr-auto"
          variant="neutral"
          size="medium"
          :aria-label="$t('Close side panel')"
          icon="x-lg"
          @click="close()"
        />
      </header>

      <div ref="content" class="h-full overflow-y-scroll px-3" v-bind="$attrs">
        <slot />
      </div>

      <footer
        v-if="$slots.footer || !hideFooter"
        ref="footer"
        :aria-label="$t('Side panel footer')"
        class="sticky bottom-0 border-t border-t-transparent bg-neutral-50 p-3 ltr:rounded-bl-xl rtl:rounded-br-xl dark:bg-gray-500"
        :class="{
          'border-t-neutral-100 dark:border-t-gray-900':
            !arrivedState.bottom && isContentOverflowing,
        }"
      >
        <slot name="footer" v-bind="{ action, close }">
          <CommonFlyoutActionFooter
            v-bind="footerActionOptions"
            :form-node-id="formNodeId"
            :is-form-disabled="isFormDisabled"
            @cancel="close(true)"
            @action="action()"
          />
        </slot>
      </footer>

      <ResizeLine
        v-if="resizable"
        ref="resize-handle"
        :label="$t('Resize side panel')"
        class="absolute top-2 h-[calc(100%-16px)] overflow-clip ltr:left-px ltr:-translate-x-1/2 rtl:right-px rtl:translate-x-1/2"
        orientation="vertical"
        :values="{
          current: flyoutContainerWidth,
          max: flyoutMaxWidth,
        }"
        @mousedown-event="startResizing"
        @touchstart-event="startResizing"
        @dblclick-event="resetWidth()"
      />
    </CommonOverlayContainer>
  </Transition>
</template>
