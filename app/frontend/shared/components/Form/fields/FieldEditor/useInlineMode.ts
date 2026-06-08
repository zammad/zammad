// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { onClickOutside } from '@vueuse/core'
import { computed, ref, watch, type Ref, type ShallowRef } from 'vue'

import { useAppName } from '#shared/composables/useAppName.ts'
import { KeyboardKey } from '#shared/composables/useKeyboardEventBus/types.ts'
import { useKeyboardEventBus } from '#shared/composables/useKeyboardEventBus/useKeyboardEventBus.ts'

import type { FieldEditorProps } from './types'
import type { FormFieldContext } from '../../types/field'

export const useInlineMode = (
  context: Ref<FormFieldContext<FieldEditorProps>>,
  wrapperElement: ShallowRef<HTMLElement | null>,
) => {
  const appName = useAppName()

  const isEditing = ref(false)
  const isSubmitting = ref(false)

  const isInlineMode = computed(() => context.value.inline)

  const onWrapperClick = () => {
    if (isEditing.value || !isInlineMode.value) return
    isEditing.value = true
  }

  const stopEditing = () => {
    isEditing.value = false
  }

  const submitToStopEditing = (waitForCallback: () => Promise<boolean>) => {
    waitForCallback().then((shouldStopEditing) => {
      if (!shouldStopEditing) return
      stopEditing()
      isSubmitting.value = false
    })
  }

  const handleCancel = () => {
    stopEditing()
    context.value?.reset?.()

    // :TODO editor sometimes keeps focus after canceling, we should find a better way to handle this
    if (document.activeElement instanceof HTMLElement) document.activeElement.blur()
  }

  const handleChange = () => {
    isSubmitting.value = true

    context.value.node.emit('change', { submitToStopEditing })
  }

  const handlerConfig = {
    key: context.value.id,
    handler: handleCancel,
  }

  const { subscribeEvent, unsubscribeEvent } = useKeyboardEventBus(
    KeyboardKey.Escape,
    handlerConfig,
  )

  const { stop } = watch(isEditing, () => {
    if (isEditing.value) {
      subscribeEvent(handlerConfig)
    } else {
      unsubscribeEvent(handlerConfig)
    }
  })

  if (!isInlineMode.value) stop()

  onClickOutside(
    wrapperElement,
    () => {
      if (!isInlineMode.value) return

      handleChange()
    },
    { ignore: ['.editor-action-popover', '.editor-overflow-popover'] },
  )

  const labelInlineDesktopClasses = 'text-stone-200! dark:text-neutral-500!'

  const wrapperInlineDesktopClasses = computed(() =>
    appName === 'desktop'
      ? {
          'rounded-b-lg pt-0!': isInlineMode.value,
          'focus-within:outline-1 focus:outline-none focus-within:-outline-offset-1 rounded-b-lg focus-within:outline-blue-800 hover:outline-1 hover:-outline-offset-1 hover:outline-blue-600 focus-within:hover:outline-blue-800 focus-visible:outline-1 dark:bg-gray-700 dark:hover:outline-blue-900 dark:focus-within:hover:outline-blue-800':
            !isInlineMode.value,
          'group-hover:bg-blue-200 dark:group-hover:bg-gray-700 rounded-b-lg group-focus-within:outline-1 group-focus-within:outline-blue-800 group-hover:outline-1 group-hover:-outline-offset-1 group-hover:outline-blue-600 group-focus-visible:outline-1 dark:group-hover:outline-blue-900':
            isInlineMode.value && !isEditing.value,
          'bg-blue-200 focus-within:outline-1 focus:outline-none focus-within:-outline-offset-1 rounded-b-lg focus-within:outline-blue-800 hover:outline-1 hover:-outline-offset-1 hover:outline-blue-600 focus-within:hover:outline-blue-800 focus-visible:outline-1 dark:bg-gray-700 dark:hover:outline-blue-900 dark:focus-within:hover:outline-blue-800':
            isInlineMode.value && isEditing.value,
        }
      : {},
  )

  const containerInlineDesktopClasses = computed(() =>
    appName === 'desktop'
      ? {
          '-mx-1 -translate-y-2 -mb-3': isInlineMode.value,
          'rounded-b-lg dark:bg-gray-700': isEditing.value && isInlineMode.value,
        }
      : {},
  )

  const inputInlineDesktopTextStyles = computed(() =>
    appName === 'desktop'
      ? {
          '--editor-text-color':
            !isInlineMode.value || isEditing.value ? 'var(--color-black)' : 'var(--color-gray-100)',
          '--editor-text-color-dark':
            !isInlineMode.value || isEditing.value
              ? 'var(--color-white)'
              : 'var(--color-neutral-400)',
        }
      : {},
  )

  return {
    isEditing,
    isSubmitting,
    isInlineMode,
    onWrapperClick,
    handleCancel,
    handleChange,
    labelInlineDesktopClasses,
    containerInlineDesktopClasses,
    wrapperInlineDesktopClasses,
    inputInlineDesktopTextStyles,
  }
}
