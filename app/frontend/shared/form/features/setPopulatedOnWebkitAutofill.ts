// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import type { FormKitNode } from '@formkit/core'

export const setPopulatedOnWebkitAutofill = (node: FormKitNode) => {
  let autofillField = false

  const onAnimationstart = (e?: AnimationEvent) => {
    if (
      !e ||
      (e.animationName !== 'onAutoFillStart' &&
        e.animationName !== 'onAutoFillEnd') ||
      (e.animationName === 'onAutoFillEnd' && !autofillField)
    )
      return

    const inputElement = e.currentTarget as HTMLInputElement

    const outerElement = inputElement.closest(
      '.formkit-outer',
    ) as HTMLDivElement

    if (!outerElement) return

    if (e.animationName === 'onAutoFillStart') {
      autofillField = true
      outerElement.dataset.populated = 'true'
      return
    }

    autofillField = false
    delete outerElement.dataset.populated
  }

  node.on('created', () => {
    if (!node.context) return

    // This is not a typo, all event handlers have just a first letter capitalized!
    node.context.attrs.onAnimationstart = onAnimationstart
  })
}
