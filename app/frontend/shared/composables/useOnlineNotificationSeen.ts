// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Ref } from 'vue'
import { watch } from 'vue'
import { useOnlineNotificationSeenMutation } from '@shared/entities/online-notification/graphql/mutations/seen.api'
import { MutationHandler } from '@shared/server/apollo/handler'
import type { ObjectWithId } from '@shared/types/utils'

export const useOnlineNotificationSeen = (
  object: Ref<ObjectWithId | undefined>,
) => {
  const seenMutation = new MutationHandler(useOnlineNotificationSeenMutation())

  const setAsSeen = async () => {
    if (!object.value?.id) return

    await seenMutation.send({ objectId: object.value.id })
  }

  watch(() => object.value?.id, setAsSeen)
}
