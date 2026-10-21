<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onClickOutside, useResizeObserver } from '@vueuse/core'
import linkifyStr from 'linkify-string'
import { escape } from 'lodash-es'
import { computed, ref, nextTick, watch, onMounted, useTemplateRef, type Directive } from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import { useHtmlLinks } from '#shared/composables/useHtmlLinks.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { i18n } from '#shared/i18n/index.ts'
import { isComposing } from '#shared/utils/events.ts'
import { getCaretOffsetFromPoint } from '#shared/utils/selection.ts'

import CommonInlineEditButtons from '#desktop/components/CommonInlineEditButtons/CommonInlineEditButtons.vue'

export interface Props {
  value: string
  initialEditValue?: string
  id?: string
  disabled?: boolean
  required?: boolean
  placeholder?: string
  size?: 'xs' | 'small' | 'medium' | 'large' | 'xl'
  alternativeBackground?: boolean
  submitLabel?: string
  cancelLabel?: string
  detectLinks?: boolean
  loading?: boolean
  labelAttrs?: Record<string, string>
  label?: string
  block?: boolean
  maxLength?: number | string
  singleLine?: boolean
  classes?: {
    label?: string
    input?: string
  }
  onSubmitEdit?: (value: string) => Promise<void | (() => void)> | void | (() => void)
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
})

const emit = defineEmits<{
  'cancel-edit': []
}>()

const target = useTemplateRef('target')

const isHoverTargetLink = ref(false)

const isValid = ref(false) // default user made no changes
const labelInstance = useTemplateRef('label')
const textareaElement = useTemplateRef('textarea')
const newEditValue = ref(props.value)

let caretOffset: number | null = null

const isEditing = defineModel<boolean>('editing', {
  default: false,
})

const activeEditingMode = computed(() => {
  return !props.disabled && isEditing.value
})

const contentTooltip = computed(() => {
  if (props.disabled) return

  if (isHoverTargetLink.value) return i18n.t('Open link')

  return props.label || i18n.t('Start editing')
})

const checkValidity = (edit: string) => {
  if (props.required) {
    isValid.value = edit.length >= 1
  } else {
    isValid.value = true
  }

  return isValid.value
}

const inputValue = computed({
  get: () => newEditValue.value,
  set: (value: string) => {
    newEditValue.value = value
    isValid.value = checkValidity(newEditValue.value)
  },
})

const stopEditing = (emitCancel = true) => {
  isEditing.value = false
  if (emitCancel) emit('cancel-edit')

  if (!newEditValue.value.length) newEditValue.value = props.initialEditValue ?? props.value
}

// The offset only maps onto the edit value as long as the label shows that very text.
const getClickedCaretOffset = (event: MouseEvent) => {
  const label = labelInstance.value?.$el as HTMLElement | undefined
  if (!label || label.textContent !== (props.initialEditValue ?? props.value)) return null

  return getCaretOffsetFromPoint(label, event.clientX, event.clientY)
}

const activateEditing = (event?: MouseEvent | KeyboardEvent) => {
  if (props.detectLinks && (event?.target as HTMLElement)?.closest('a')) return // guard to prevent editing when clicking on a link

  if (isEditing.value || props.disabled) return

  caretOffset = event instanceof MouseEvent ? getClickedCaretOffset(event) : null

  isEditing.value = true
}

const submitEdit = () => {
  // Needs to be checked, because the 'onSubmit' function is not required.
  if (!props.onSubmitEdit) return undefined

  // Don't trigger a mutation if there is no change
  if (props.value === newEditValue.value) return stopEditing(false)

  if (!checkValidity(inputValue.value)) return

  const submitEditResult = props.onSubmitEdit(inputValue.value)

  if (submitEditResult instanceof Promise) {
    return submitEditResult
      .then((result) => {
        result?.()

        stopEditing(false)
      })
      .catch(() => {}) // :TODO if promise rejects should we not show something to the user?
  }

  submitEditResult?.()

  stopEditing(false)
}

const handleMouseOver = (event: MouseEvent) => {
  if (!props.detectLinks) return

  if ((event.target as HTMLElement).closest('a')) {
    isHoverTargetLink.value = true
    return
  }
  isHoverTargetLink.value = false
}

const handleMouseLeave = () => {
  if (!props.detectLinks) return
  isHoverTargetLink.value = false
}

onClickOutside(target, () => {
  if (isEditing.value) return submitEdit()
  stopEditing()
})

const { setupLinksHandlers } = useHtmlLinks('/desktop')

const handleEnterKey = (event: KeyboardEvent) => {
  if (isComposing(event)) return

  event.preventDefault()
  submitEdit()
}

const handleEscapeKey = (event: KeyboardEvent) => {
  if (isComposing(event)) return

  stopEditing()
}

const processedContent = computed(() => {
  if (props.detectLinks) return linkifyStr(props.value)
  return escape(props.value)
})

useTrapTab(target)

watch(
  () => props.value,
  () => {
    if (props.detectLinks && labelInstance.value?.$el) setupLinksHandlers(labelInstance.value?.$el)
  },
  {
    flush: 'post',
  },
)

onMounted(() => {
  nextTick(() => {
    if (props.detectLinks && labelInstance.value?.$el) setupLinksHandlers(labelInstance.value?.$el)
  })
})

watch(isEditing, () => {
  newEditValue.value = props.initialEditValue ?? props.value
})

// Grows by whole lines: a height taken from the rounded scrollHeight is up to a pixel off the label.
const resizeTextarea = () => {
  const textarea = textareaElement.value
  if (!textarea) return

  const lineHeight = parseFloat(getComputedStyle(textarea).lineHeight)
  if (!lineHeight) return

  textarea.rows = 1
  textarea.rows = Math.max(1, Math.round(textarea.scrollHeight / lineHeight))
}

watch([textareaElement, inputValue], resizeTextarea, { flush: 'post' })

useResizeObserver(textareaElement, resizeTextarea)

const focusField = (el: HTMLInputElement | HTMLTextAreaElement, onFocus?: () => void) => {
  nextTick(() => {
    // Add this to the event loop to ensure when clicking fast between inputs does not loose focus
    setTimeout(() => {
      el.focus()
      onFocus?.()
    }, 0)
  })
}

// Places the caret only once, so a re-render while typing does not move it.
const vFocus: Directive<HTMLInputElement | HTMLTextAreaElement> = {
  mounted: (el) => {
    checkValidity(inputValue.value)

    const offset = caretOffset
    caretOffset = null

    focusField(el, () => {
      const position = Math.min(offset ?? el.value.length, el.value.length)
      el.setSelectionRange(position, position)
    })
  },
  updated: (el) => focusField(el),
}

// Styling
const focusClasses = computed(() => {
  let classes =
    'group-focus-within:before:absolute group-focus-within:before:top-1/2 group-focus-within:before:left-[-5px] group-focus-within:before:z-0 group-focus-within:before:size-[calc(100%+10px)] group-focus-within:before:-translate-y-1/2 group-focus-within:before:rounded-md group-focus-visible:before:outline-1 group-focus-visible:before:outline-blue-800'

  if (props.alternativeBackground) {
    classes += ' group-focus-within:before:bg-neutral-50 dark:group-focus-within:before:bg-gray-500'
  } else {
    classes += ' group-focus-within:before:bg-blue-200 dark:group-focus-within:before:bg-gray-700'
  }
  return classes
})

const focusNonEditClasses = computed(() => ({
  [focusClasses.value]: !isEditing.value && !props.disabled,
}))

const disabledClasses = computed(() => ({
  'cursor-text': props.disabled,
}))

const fontSizeClassMap = {
  xs: 'text-[10px] leading-[10px]',
  small: 'text-xs leading-snug',
  medium: 'text-sm leading-snug',
  large: 'text-base leading-snug',
  xl: 'text-xl leading-snug',
}

const minHeightClassMap = {
  xs: 'min-h-2',
  small: 'min-h-3',
  medium: 'min-h-4',
  large: 'min-h-5',
  xl: 'min-h-6',
}

const editBackgroundClass = computed(() =>
  props.alternativeBackground
    ? 'before:bg-neutral-50 dark:before:bg-gray-500'
    : 'before:bg-blue-200 dark:before:bg-gray-700',
)

const hoverClasses = computed(() => {
  let classes =
    'before:absolute before:top-1/2 before:left-[-5px] before:-z-10 before:size-[calc(100%+10px)] before:-translate-y-1/2 before:rounded-md'

  if (props.alternativeBackground) {
    classes +=
      ' hover:before:bg-neutral-50 dark:hover:before:bg-gray-500 hover:before:outline-1 hover:before:outline-blue-600 hover:dark:before:outline-blue-900'
  } else {
    classes +=
      ' hover:before:bg-blue-200 dark:hover:before:bg-gray-700 hover:before:outline-1 hover:before:outline-blue-600 hover:dark:before:outline-blue-900' // default background
  }

  return props.disabled ? '' : classes
})

defineExpose({
  activateEditing,
  isEditing,
})
</script>

<template>
  <!-- eslint-disable vuejs-accessibility/no-static-element-interactions,vuejs-accessibility/mouse-events-have-key-events-->
  <div
    ref="target"
    :role="activeEditingMode || disabled ? undefined : 'button'"
    class="group relative flex w-fit items-center gap-1"
    :class="[
      disabledClasses,
      {
        'w-full': block,
      },
    ]"
    :aria-disabled="disabled"
    :tabindex="activeEditingMode || disabled ? undefined : 0"
    @click.capture="activateEditing"
    @keydown.enter.capture="activateEditing"
    @mouseover="handleMouseOver"
    @mouseleave="handleMouseLeave"
    @keydown.esc="handleEscapeKey"
  >
    <div
      v-if="!isEditing"
      v-tooltip="contentTooltip"
      class="Content relative z-0 flex grow items-center"
      :class="[
        {
          grow: block,
          'invisible opacity-0': isEditing,
        },
        focusNonEditClasses,
        hoverClasses,
      ]"
    >
      <!-- Reserves the room of the edit buttons, so the text wraps the same way in both modes. -->
      <CommonLabel
        :id="id"
        ref="label"
        v-tooltip.supportive.truncate="processedContent"
        class="z-10 wrap-break-word whitespace-pre-wrap"
        :style="{ wordBreak: 'normal', overflowWrap: 'anywhere' }"
        v-bind="labelAttrs"
        :size="size"
        :class="[{ 'pe-14': !disabled }, classes?.label, minHeightClassMap[size]]"
      >
        <!-- One element, else the text and its links become separate flex items of the label. -->
        <!-- eslint-disable-next-line vue/no-v-html -->
        <span v-html="processedContent" />
      </CommonLabel>
    </div>

    <div
      v-else
      class="flex max-w-full items-center gap-2 before:absolute before:top-1/2 before:-left-1.25 before:z-0 before:size-[calc(100%+10px)] before:-translate-y-1/2 before:rounded-md focus-within:before:outline-1 focus-within:before:outline-blue-800"
      :class="[{ 'w-full': block }, editBackgroundClass, fontSizeClassMap[size]]"
    >
      <div class="relative z-10 w-full pe-14">
        <input
          v-if="singleLine"
          key="editable-content-key"
          v-model.trim="inputValue"
          v-focus
          class="block w-full shrink-0 bg-transparent text-normal outline-hidden"
          :class="[{ grow: block }, classes?.input || '']"
          :disabled="disabled || loading"
          :aria-label="label"
          :placeholder="placeholder"
          :maxlength="maxLength"
          @keydown.stop.enter="handleEnterKey"
        />
        <textarea
          v-else
          key="editable-content-multi-line-key"
          ref="textarea"
          v-model.trim="inputValue"
          v-focus
          rows="1"
          class="block w-full shrink-0 resize-none overflow-hidden bg-transparent wrap-break-word text-normal outline-hidden"
          :style="{ wordBreak: 'normal', overflowWrap: 'anywhere' }"
          :class="[{ grow: block }, classes?.input || '']"
          :disabled="disabled || loading"
          :aria-label="label"
          :placeholder="placeholder"
          :maxlength="maxLength"
          @keydown.stop.enter="handleEnterKey"
        />

        <!-- One line high and at the bottom, so the buttons are centered on the last line, where typing ends. -->
        <CommonInlineEditButtons
          :submit-label="submitLabel"
          :cancel-label="cancelLabel"
          class="absolute inset-e-0 bottom-0 h-lh items-center print:hidden"
          :submit-disabled="!isValid"
          @submit="submitEdit"
          @cancel="stopEditing()"
        />
      </div>
    </div>
  </div>
</template>
