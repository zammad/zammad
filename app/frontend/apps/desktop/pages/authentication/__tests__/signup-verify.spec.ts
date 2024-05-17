// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

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
      view.getByText(
        'Email could not be verified. Please contact your administrator.',
      ),
    ).toBeInTheDocument()
  })

  it('shows a loading indicator during the verification process', async () => {
    const view = await visitView('/signup/verify/123')

    expect(view.getByText('Verifying your email…')).toBeInTheDocument()

    const loader = view.getByRole('status')

    expect(getByIconName(loader, 'spinner')).toBeInTheDocument()
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
      await view.findByText(
        'Email could not be verified. Please contact your administrator.',
      ),
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

    await vi.waitFor(() => {
      const router = getTestRouter()
      const route = router.currentRoute.value
      expect(route.name).toBe('Dashboard')
    })
  })
})
