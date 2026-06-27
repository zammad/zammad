// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import mitt, { type Emitter } from 'mitt'

type StaticEvents = {
  'session-invalid': void
  'focus-quick-search-field': void
  'reset-quick-search-field': void
  'primary-sidebar-transition': void
  'resize-layout': void
  'close-popover': void
  'websocket-open': void
  'websocket-close': void
  reconnected: void
}

type DynamicEvents = {
  [key in
    | `customer-ticket-list-refetch:${string}`
    | `organization-ticket-list-refetch:${string}`]: void
}

export type Events = StaticEvents & DynamicEvents

const emitter: Emitter<Events> = mitt<Events>()

export default emitter
