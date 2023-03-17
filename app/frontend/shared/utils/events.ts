// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { StopEventOptions } from '@shared/types/events'

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

export default stopEvent
