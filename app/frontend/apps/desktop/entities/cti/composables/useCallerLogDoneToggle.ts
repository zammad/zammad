// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getApolloClient } from '#shared/server/apollo/client.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useCtiLogDoneUpdateMutation } from '#desktop/entities/cti/graphql/mutations/ctiLogDoneUpdate.api.ts'

type CallerLogDoneEntry = {
  __typename?: string
  id: string
  done: boolean
}

export const useCallerLogDoneToggle = () => {
  const doneMutation = new MutationHandler(useCtiLogDoneUpdateMutation(), {
    errorNotificationMessage: __('The call could not be updated.'),
  })

  // Optimistic like the caller notification: the checkbox follows the click instead of the
  //   round trip. The mutation carries the value the agent saw rather than a toggle, so a change
  //   another agent made in the meantime is not flipped back, and the returned entry is the
  //   server's word on the row.
  const toggleDone = (entry: CallerLogDoneEntry) => {
    const done = !entry.done
    const { cache } = getApolloClient()
    const id = cache.identify(entry)

    cache.modify({ id, fields: { done: () => done } })

    return doneMutation.send({ id: entry.id, done }).catch(() => {
      // Only the optimistic value is taken back; a value the subscription delivered meanwhile stays.
      cache.modify({
        id,
        fields: { done: (current: boolean) => (current === done ? !done : current) },
      })
    })
  }

  return { toggleDone }
}
