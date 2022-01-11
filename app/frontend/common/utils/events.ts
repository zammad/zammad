// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { StopEventOptions } from '@common/types/events'

const stopEvent = (event: Event, stopOptions: StopEventOptions): void => {
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
