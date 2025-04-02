<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onClickOutside } from '@vueuse/core'
import {
  computed,
  defineAsyncComponent,
  ref,
  nextTick,
  watch,
  onMounted,
  useTemplateRef,
} from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import { useHtmlLinks } from '#shared/composables/useHtmlLinks.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { i18n } from '#shared/i18n/index.ts'
import { textToHtml } from '#shared/utils/helpers.ts'

const CommonButton = defineAsyncComponent(
  () => import('#desktop/components/CommonButton/CommonButton.vue'),
)

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
  classes?: {
    label?: string
    input?: string
  }
  onSubmitEdit?: (
    value: string,
  ) => Promise<void | (() => void)> | void | (() => void)
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
const newEditValue = ref(props.value)

const isEditing = defineModel<boolean>('editing', {
  default: false,
})

const activeEditingMode = computed(() => {
  return !props.disabled && isEditing.value
})

const contentTooltip = computed(() => {
  if (props.disabled) return

  if (isHoverTargetLink.value) return i18n.t('Open link')

  return props.label || i18n.t('Start Editing')
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

  if (!newEditValue.value.length)
    newEditValue.value = props.initialEditValue ?? props.value
}

const activateEditing = (event?: MouseEvent | KeyboardEvent) => {
  if (props.detectLinks && (event?.target as HTMLElement)?.closest('a')) return // guard to prevent editing when clicking on a link

  if (isEditing.value || props.disabled) return

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
  event.preventDefault()
  submitEdit()
}

const processedContent = computed(() => {
  if (props.detectLinks) return textToHtml(props.value)
  return props.value
})

useTrapTab(target)

watch(
  () => props.value,
  () => {
    if (props.detectLinks && labelInstance.value?.$el)
      setupLinksHandlers(labelInstance.value?.$el)
  },
  {
    flush: 'post',
  },
)

onMounted(() => {
  nextTick(() => {
    if (props.detectLinks && labelInstance.value?.$el)
      setupLinksHandlers(labelInstance.value?.$el)
  })
})

watch(isEditing, () => {
  newEditValue.value = props.initialEditValue ?? props.value
})

const vFocus = (el: HTMLElement) => {
  checkValidity(inputValue.value)

  nextTick(() => {
    // Add this to the event loop to ensure when clicking fast between inputs does not loose focus
    setTimeout(() => {
      el.focus()
    }, 0)
  })
}

// Styling
const focusClasses = computed(() => {
  let classes =
    'group-focus-within:before:absolute group-focus-within:before:-left-[5px] group-focus-within:before:top-1/2 group-focus-within:before:z-0 group-focus-within:before:h-[calc(100%+10px)] group-focus-within:before:w-[calc(100%+10px)] group-focus-within:before:-translate-y-1/2 group-focus-within:before:rounded-md'

  if (props.alternativeBackground) {
    classes +=
      ' group-focus-within:before:bg-neutral-50 group-focus-within:before:dark:bg-gray-500'
  } else {
    classes +=
      ' group-focus-within:before:bg-blue-200 group-focus-within:before:dark:bg-gray-700'
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
    'before:absolute before:-left-[5px] before:top-1/2 before:-translate-y-1/2 before:-z-10 before:h-[calc(100%+10px)] before:w-[calc(100%+10px)] before:rounded-md'

  if (props.alternativeBackground) {
    classes += ' hover:before:bg-neutral-50 dark:hover:before:bg-gray-500'
  } else {
    classes += ' hover:before:bg-blue-200 dark:hover:before:bg-gray-700' // default background
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
    class="group relative flex w-fit items-center gap-1 focus:outline-hidden"
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
    @keydown.esc="stopEditing()"
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
      <!--   eslint-disable vue/no-v-text-v-html-on-component vue/no-v-html   -->
      <CommonLabel
        :id="id"
        ref="label"
        class="z-10 break-words"
        style="word-break: normal; overflow-wrap: anywhere"
        v-bind="labelAttrs"
        :size="size"
        :class="[classes?.label, minHeightClassMap[size]]"
        v-html="processedContent"
      />
    </div>

    <div
      v-else
      class="flex max-w-full items-center gap-2 before:absolute before:top-1/2 before:-left-[5px] before:z-0 before:h-[calc(100%+10px)] before:w-[calc(100%+10px)] before:-translate-y-1/2 before:rounded-md"
      :class="[
        { 'w-full': block },
        editBackgroundClass,
        fontSizeClassMap[size],
      ]"
    >
      <div class="relative z-10 w-full ltr:pr-14 rtl:pl-14">
        <input
          key="editable-content-key"
          v-model.trim="inputValue"
          v-focus
          class="block w-full flex-shrink-0 bg-transparent text-gray-100 outline-hidden dark:text-neutral-400"
          :class="[{ grow: block }, classes?.input || '']"
          :disabled="disabled || loading"
          :placeholder="placeholder"
          @keydown.stop.enter="handleEnterKey"
        />
      </div>

      <div class="absolute z-10 flex gap-1 ltr:right-0 rtl:left-0 rtl:-order-1">
        <CommonButton
          v-tooltip="cancelLabel || $t('Cancel')"
          icon="x-lg"
          variant="danger"
          @click="stopEditing()"
          @keydown.enter.stop="stopEditing()"
        />
        <CommonButton
          v-tooltip="submitLabel || $t('Save changes')"
          class="rtl:-order-1"
          icon="check2"
          :disabled="!isValid"
          variant="submit"
          @click="submitEdit"
          @keydown.enter.stop="submitEdit"
        />
      </div>
    </div>
  </div>
</template>
