// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { watch } from 'vue'

import { useOnlineNotificationSeenMutation } from '#shared/entities/online-notification/graphql/mutations/seen.api.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import type { ObjectWithId } from '#shared/types/utils.ts'

import type { Ref } from 'vue'

export const useOnlineNotificationSeen = (object: Ref<ObjectWithId | undefined>) => {
  const seenMutation = new MutationHandler(useOnlineNotificationSeenMutation())

  const setAsSeen = async () => {
    if (!object.value?.id) return

    await seenMutation.send({ objectId: object.value.id })
  }

  // Immediate, because the object can already be there when this runs - a cached query answers
  //   synchronously, and a plain watcher would never see that first value.
  watch(() => object.value?.id, setAsSeen, { immediate: true })
}
