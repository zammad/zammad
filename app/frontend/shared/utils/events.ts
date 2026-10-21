// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { StopEventOptions } from '#shared/types/events.ts'

const stopEvent = (event: Event, stopOptions: StopEventOptions = {}): void => {
  const {
    preventDefault = true,
    propagation = true,
    immediatePropagation = false,
  }: StopEventOptions = stopOptions

  if (preventDefault) {
    event.preventDefault()
  }
  if (propagation) {
    event.stopPropagation()
  }
  if (immediatePropagation) {
    event.stopImmediatePropagation()
  }
}

// Safari reports the keydown that commits an IME composition with keyCode 229, but not as composing.
export const isComposing = (event: KeyboardEvent) => event.isComposing || event.keyCode === 229

export default stopEvent
