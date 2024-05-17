// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { isNavigationFailure } from 'vue-router'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { mockTicketOverviews } from '#tests/support/mocks/ticket-overviews.ts'

import { EnumAfterAuthType } from '#shared/graphql/types.ts'

import { ensureAfterAuth } from '../after-auth/composable/useAfterAuthPlugins.ts'

it("doesn't open the page if there is nothing to show", async () => {
  mockUserCurrent({ id: '666' })
  mockTicketOverviews()

  const view = await visitView('/login/after-auth')

  expect(view.queryByTestId('loginAfterAuth')).not.toBeInTheDocument()
})

it('user cannot leave the after auth page', async () => {
  const view = await visitView('/testing-environment')
  const router = getTestRouter()
  router.restoreMethods()
  await ensureAfterAuth(router, {
    type: EnumAfterAuthType.TwoFactorConfiguration,
  })

  expect(await view.findByTestId('loginAfterAuth')).toBeInTheDocument()

  const error = await router.push('/login')

  expect(isNavigationFailure(error)).toBe(true)
  expect(view.queryByTestId('loginAfterAuth')).toBeInTheDocument()
})
