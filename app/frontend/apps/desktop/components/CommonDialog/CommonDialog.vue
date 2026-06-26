<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, onMounted, useTemplateRef, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import {
  KeyboardKey,
  type OrderKeyHandlerConfig,
} from '#shared/composables/useKeyboardEventBus/types.ts'
import { useKeyboardEventBus } from '#shared/composables/useKeyboardEventBus/useKeyboardEventBus.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { getFirstFocusableElement } from '#shared/utils/getFocusableElements.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonOverlayContainer from '#desktop/components/CommonOverlayContainer/CommonOverlayContainer.vue'
import { useAppBreakpoints } from '#desktop/composables/responsiveness/useAppBreakpoints.ts'
import { getRouteIdentifier } from '#desktop/composables/useOverlayContainer.ts'
import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'

import CommonDialogActionFooter, {
  type Props as ActionFooterProps,
} from './CommonDialogActionFooter.vue'
import { closeDialog } from './useDialog.ts'

export interface Props {
  name: string
  headerTitle?: string
  headerIcon?: string
  content?: string
  contentPlaceholder?: string[]
  hideFooter?: boolean
  /**
   * Inner wrapper for the dialog content.
   * */
  wrapperTag?: 'div' | 'article'
  footerActionOptions?: ActionFooterProps
  // Don't focus the first element inside a Dialog after being mounted
  // if nothing is focusable, will focus "Close" button when dismissable is active.
  noAutofocus?: boolean
  fullscreen?: boolean
  global?: boolean
  escapeConfig?: Pick<OrderKeyHandlerConfig, 'beforeHandlerRuns' | 'handler'>
  noClose?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  wrapperTag: 'div',
})

defineOptions({
  inheritAttrs: false,
})

const emit = defineEmits<{
  close: [cancel?: boolean]
}>()

const routeIdentifier = getRouteIdentifier(useRoute())

const router = useRouter()

const isActive = computed(() =>
  props.fullscreen ? true : routeIdentifier === getRouteIdentifier(router.currentRoute.value),
)

const { isSmallScreen } = useAppBreakpoints()

const isFullscreen = computed(() => props.fullscreen || isSmallScreen.value)

const dialogElement = useTemplateRef<HTMLElement>('dialog')
const footerElement = useTemplateRef('footer')
const contentElement = useTemplateRef('content')

const close = async (cancel?: boolean) => {
  if (props.noClose) return

  // Close event will be emitted only if `noClose` prop is not set
  //   To handle the actions in this case, please override the `#footer` slot.
  emit('close', cancel)
  await closeDialog(props.name, props.global)
}

const dialogId = `dialog-${props.name}`

const escapeConfig: OrderKeyHandlerConfig = {
  handler: close,
  key: dialogId,
  beforeHandlerRuns: props.escapeConfig?.beforeHandlerRuns,
}

const { unsubscribeEvent, subscribeEvent } = useKeyboardEventBus(KeyboardKey.Escape, escapeConfig)

watch(isActive, (isActive) =>
  isActive ? subscribeEvent(escapeConfig) : unsubscribeEvent(escapeConfig),
)

useTrapTab(dialogElement)

onMounted(() => {
  if (props.noAutofocus) return

  // Will try to find a focusable element inside dialog main and footer content.
  // If it doesn't find it, will try to find inside the header most likely will find "Close" button.
  const firstFocusable =
    getFirstFocusableElement(contentElement.value) ||
    getFirstFocusableElement(footerElement.value) ||
    getFirstFocusableElement(dialogElement.value)

  nextTick(() => {
    firstFocusable?.focus()
    firstFocusable?.scrollIntoView({ block: 'nearest' })
  })
})

const { transitions } = useTransitionConfig()
</script>

<template>
  <!--  `display:none` to prevent showing up inactive dialog for cached instance -->
  <Transition :name="transitions.fade" :appear="isActive">
    <!-- We use teleport here to  center it to target node and increase z index on fullscreen to avoid clicking collapse and resize buttons -->
    <Teleport :to="isFullscreen ? '#app' : '#main-content'">
      <CommonOverlayContainer
        :id="dialogId"
        tag="div"
        disable-teleport
        class="absolute top-[50%] z-50 size-full translate-y-[-50%] ltr:left-[50%] ltr:translate-x-[-50%] rtl:right-[50%] rtl:-translate-x-[-50%]"
        :class="{ 'z-40': isFullscreen, hidden: !isActive }"
        role="dialog"
        backdrop-class="z-40"
        :show-backdrop="isActive"
        :fullscreen="fullscreen"
        :aria-labelledby="`${dialogId}-title`"
        :no-close-on-backdrop-click="noClose"
        @click-background="close()"
      >
        <component
          :is="wrapperTag"
          ref="dialog"
          data-common-dialog
          class="absolute top-1/2 z-50 flex w-max max-w-full -translate-y-1/2 flex-col gap-3 rounded-xl border border-neutral-100 bg-neutral-50 p-3 md:min-w-lg ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2 dark:border-gray-900 dark:bg-gray-500"
        >
          <div class="flex items-center justify-between bg-neutral-50 dark:bg-gray-500">
            <slot name="header">
              <div
                class="flex items-center gap-2 text-xl leading-snug text-gray-100 dark:text-neutral-400"
              >
                <CommonIcon v-if="headerIcon" size="small" :name="headerIcon" />
                <h3 :id="`${dialogId}-title`">{{ $t(headerTitle) }}</h3>
              </div>
            </slot>
            <CommonButton
              v-if="!noClose"
              v-tooltip="$t('Close dialog')"
              class="ms-auto"
              variant="neutral"
              size="medium"
              icon="x-lg"
              @click="close()"
            />
          </div>
          <div ref="content" v-bind="$attrs" class="py-6 text-center">
            <slot>
              <CommonLabel size="large">{{
                $t(content, ...(contentPlaceholder || []))
              }}</CommonLabel>
            </slot>
          </div>
          <div v-if="$slots.footer || !hideFooter" ref="footer">
            <slot name="footer">
              <CommonDialogActionFooter
                v-bind="footerActionOptions"
                @cancel="close(true)"
                @action="close(false)"
              />
            </slot>
          </div>
        </component>
      </CommonOverlayContainer>
    </Teleport>
  </Transition>
</template>
