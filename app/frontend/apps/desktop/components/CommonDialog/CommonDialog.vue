<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onKeyUp } from '@vueuse/core'
import { useTemplateRef, nextTick, onMounted } from 'vue'

import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import stopEvent from '#shared/utils/events.ts'
import { getFirstFocusableElement } from '#shared/utils/getFocusableElements.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonOverlayContainer from '#desktop/components/CommonOverlayContainer/CommonOverlayContainer.vue'

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

const dialogElement = useTemplateRef<HTMLElement>('dialog')
const footerElement = useTemplateRef('footer')
const contentElement = useTemplateRef('content')

const close = async (cancel?: boolean) => {
  emit('close', cancel)
  await closeDialog(props.name)
}

const dialogId = `dialog-${props.name}`

onKeyUp('Escape', (e) => {
  stopEvent(e)
  close()
})

useTrapTab(dialogElement)

onMounted(() => {
  if (props.noAutofocus) return

  // Will try to find focusable element inside dialog main and footer content.
  // If it won't find it, will try to find inside the header most likely will find "Close" button.
  const firstFocusable =
    getFirstFocusableElement(contentElement.value) ||
    getFirstFocusableElement(footerElement.value) ||
    getFirstFocusableElement(dialogElement.value)

  nextTick(() => {
    firstFocusable?.focus()
    firstFocusable?.scrollIntoView({ block: 'nearest' })
  })
})
</script>

<template>
  <CommonOverlayContainer
    :id="dialogId"
    tag="div"
    class="fixed top-[50%] z-50 w-[500px] translate-y-[-50%] ltr:left-[50%] ltr:translate-x-[-50%] rtl:right-[50%] rtl:-translate-x-[-50%]"
    backdrop-class="z-40"
    role="dialog"
    :aria-labelledby="`${dialogId}-title`"
    @click-background="close()"
  >
    <component
      :is="wrapperTag"
      ref="dialog"
      data-common-dialog
      class="flex flex-col gap-3 rounded-xl border border-neutral-100 bg-neutral-50 p-3 dark:border-gray-900 dark:bg-gray-500"
    >
      <div
        class="flex items-center justify-between bg-neutral-50 dark:bg-gray-500"
      >
        <slot name="header">
          <div
            class="flex items-center gap-2 text-xl leading-snug text-gray-100 dark:text-neutral-400"
          >
            <CommonIcon v-if="headerIcon" size="small" :name="headerIcon" />
            <h3 :id="`${dialogId}-title`">{{ $t(headerTitle) }}</h3>
          </div>
        </slot>
        <CommonButton
          class="ms-auto"
          variant="neutral"
          size="medium"
          icon="x-lg"
          :aria-label="$t('Close dialog')"
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
</template>
