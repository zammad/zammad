// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'email',
  actionName: __('Email'),
  content: (event) => {
    return {
      description: __('sent to'),
      details: event.changes?.to,
    }
  },
}
