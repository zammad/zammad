// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { User } from '#shared/graphql/types.ts'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'removed-mention',
  actionName: 'removed',
  content: (event) => {
    return {
      description: __('Mention for'),
      details:
        event.object?.__typename === 'User'
          ? (event.object as User).fullname
          : '-',
    }
  },
}
