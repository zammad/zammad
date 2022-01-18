// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import mitt, { type Emitter } from 'mitt'

type Events = {
  sessionInvalid: void
}

const emitter: Emitter<Events> = mitt<Events>()

export default emitter
