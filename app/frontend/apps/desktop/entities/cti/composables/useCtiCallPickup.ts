// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'
import { useRouter } from 'vue-router'

import { useDocumentVisibility } from '#shared/composables/useDocumentVisibility.ts'
import { EnumCtiPickupView, type CtiCallPickupSubscription } from '#shared/graphql/types.ts'
import { SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useCtiCallPickupSubscription } from '#desktop/entities/cti/graphql/subscriptions/ctiCallPickup.api.ts'
import { callerTicketCreateRoute } from '#desktop/entities/cti/utils/routeLocation.ts'

import { useCtiAccess } from './useCtiAccess.ts'

type PickupTarget = NonNullable<CtiCallPickupSubscription['ctiCallPickup']['target']>

// How long a hidden browser tab holds a target for the agent to turn to it.
const DEFERRED_TARGET_TIMEOUT = 60_000

// Opens the view the server resolved for a call the current user picked up, from
//   whatever screen they are on. Whether a view opens at all is decided there,
//   including the caller notification preference, so nothing is re-checked here.
export const useCtiCallPickup = () => {
  const router = useRouter()
  const session = useSessionStore()

  const { isIntegrationEnabled } = useCtiAccess()
  const { whenVisible } = useDocumentVisibility()

  const isEnabled = computed(
    () => isIntegrationEnabled.value && session.hasPermission('cti.agent+ticket.agent'),
  )

  const openTarget = (target: PickupTarget) => {
    if (target.view === EnumCtiPickupView.UserDetail && target.customer) {
      return router.push({
        name: 'UserDetailView',
        params: { internalId: target.customer.internalId },
      })
    }

    return router.push(callerTicketCreateRoute(target.log, target.customer))
  }

  const pickupSubscription = new SubscriptionHandler(
    useCtiCallPickupSubscription(() => ({ enabled: isEnabled.value })),
  )

  pickupSubscription.onResult((result) => {
    const target = result.data?.ctiCallPickup.target

    if (!target) return

    // Every browser tab of the agent receives the push. A hidden one holds the
    //   target in case the agent turns to it for the call, and forgets it after
    //   the timeout rather than opening a view for a call long over.
    whenVisible(() => openTarget(target), DEFERRED_TARGET_TIMEOUT)
  })
}
