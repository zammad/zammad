// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { createDeferred } from '#shared/utils/helpers.ts'

import { mockUserSignupVerifyMutation } from '../graphql/mutations/userSignupVerify.mocks.ts'

describe('signup verify view', () => {
  beforeEach(() => {
    mockApplicationConfig({
      user_create_account: true,
    })
  })

  it('shows an error message without the token parameter', async () => {
    const view = await visitView('/signup/verify')

    expect(
      view.getByText('Email could not be verified. Please contact your administrator.'),
    ).toBeInTheDocument()
  })

  it('shows a loading indicator during the verification process', async () => {
    vi.useFakeTimers()

    const { resolve, promise } = createDeferred()

    // This is caused by the fact that it never works from the timing perspective
    // We need to mock a pending promise to test the loading state, since
    // CommonLoader has a build int delay which is running in a micro task
    vi.spyOn(MutationHandler.prototype, 'send').mockReturnValue(promise)
    const view = await visitView('/signup/verify/123')

    expect(view.getByText('Verifying your email…')).toBeInTheDocument()

    await flushPromises()
    await vi.advanceTimersByTimeAsync(0)

    const loader = await view.findAllByRole('progressbar')

    expect(loader).toHaveLength(3)
    resolve(null)
    vi.resetAllMocks()
  })

  it('shows an error message when an invalid token is supplied', async () => {
    mockUserSignupVerifyMutation({
      userSignupVerify: {
        session: null,
        errors: [{ message: 'The provided token is invalid.' }],
      },
    })

    const view = await visitView('/signup/verify/123')

    expect(
      await view.findByText('Email could not be verified. Please contact your administrator.'),
    ).toBeInTheDocument()
  })

  it('shows a success message when a valid token is supplied', async () => {
    const view = await visitView('/signup/verify/123')

    expect(
      await view.findByText('Woo hoo! Your email address has been verified!'),
    ).toBeInTheDocument()
  })

  it('redirects to dashboard screen when the verification was successful', async () => {
    vi.useFakeTimers()

    await visitView('/signup/verify/123')

    await vi.runAllTimersAsync()
    vi.useRealTimers()

    await waitFor(() => {
      const router = getTestRouter()
      const route = router.currentRoute.value
      expect(route.name).toBe('Dashboard')
    })
  })
})
