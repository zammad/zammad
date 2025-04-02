// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import mitt, { type Emitter } from 'mitt'

type Events = {
  sessionInvalid: void
  'expand-collapsed-content': string
  'focus-quick-search-field': void
  'reset-quick-search-field': void
  'main-sidebar-transition': void
}

const emitter: Emitter<Events> = mitt<Events>()

export default emitter
