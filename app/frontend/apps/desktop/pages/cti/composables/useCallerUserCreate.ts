// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useRouter } from 'vue-router'

import type { UserAddMutation } from '#shared/graphql/types.ts'

import { customerTicketCreateRoute } from '#desktop/entities/cti/utils/routeLocation.ts'
import { useUserCreate } from '#desktop/entities/user/composables/useUserCreate.ts'

// The caller is unknown, so the agent creates the user first; the ticket for the call
//   follows right away, with the new user as its customer.
export const useCallerUserCreate = () => {
  const router = useRouter()

  const { openUserCreateFlyout } = useUserCreate()

  const openCallerUserCreateFlyout = (phone: string) =>
    openUserCreateFlyout({
      phone,
      onSuccess: (data) => {
        const user = (data as UserAddMutation).userAdd?.user
        if (!user) return

        router.push(customerTicketCreateRoute(user))
      },
    })

  return { openCallerUserCreateFlyout }
}
