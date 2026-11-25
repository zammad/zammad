// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode, type FormKitNode } from '@formkit/core'

import { useKeyboardShortcut } from '#shared/composables/useKeyboardShortcut/useKeyboardShortcut.ts'

/**
 * The form of the field that has the focus, found through the form's node rather than the DOM, as
 *   a field can be rendered outside its form element.
 */
export const findFocusedFormNode = (): FormKitNode | undefined => {
  let element = document.activeElement

  while (element) {
    const root = element.id ? getNode(element.id)?.at('$root') : undefined

    // An input that a field renders as a node of its own belongs to no form, the field around it does.
    if (root?.props.type === 'form') return root

    element = element.parentElement
  }
}

const findSubmitButton = () => {
  const formId = findFocusedFormNode()?.props.id
  if (!formId) return

  const formElement = document.getElementById(formId)
  if (!(formElement instanceof HTMLFormElement)) return

  // The form's elements include a button that belongs to it through its `form` attribute.
  const submitButton = Array.from(formElement.elements).find(
    (element): element is HTMLButtonElement =>
      element instanceof HTMLButtonElement && element.type === 'submit',
  )

  if (!submitButton || submitButton.disabled) return

  return { formElement, submitButton }
}

/**
 * Submits the form around the focused field like its submit button does. A form without one, or
 *   with a disabled one, is not submitted and the key press is left alone.
 */
export const useFormSubmitShortcut = () =>
  useKeyboardShortcut(
    'submit-form',
    () => {
      const target = findSubmitButton()

      target?.formElement.requestSubmit(target.submitButton)
    },
    { enabled: () => !!findSubmitButton() },
  )
