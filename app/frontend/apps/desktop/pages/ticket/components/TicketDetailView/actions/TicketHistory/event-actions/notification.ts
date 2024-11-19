// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'notification',
  actionName: 'notification',
  content: (event) => {
    const notification = event.changes?.to as string

    const match = notification.match(/^(?<email>[^(]+)\((?<details>[^)]+)\)$/)

    return {
      details: match?.groups?.email,
      additionalDetails: match?.groups?.details,
    }
  },
}
