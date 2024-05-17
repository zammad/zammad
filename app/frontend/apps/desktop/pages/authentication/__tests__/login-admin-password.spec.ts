// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockGraphQLResult } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import type { AdminPasswordAuthVerifyMutation } from '#shared/graphql/types.ts'

import { AdminPasswordAuthVerifyDocument } from '../graphql/mutations/adminPasswordAuthVerify.api.ts'

describe('verifying a token for the admin password auth', () => {
  it('shows the regular password login if the token is valid', async () => {
    mockApplicationConfig({
      user_show_password_login: false,
      auth_saml: true,
    })

    const mocker = mockGraphQLResult<AdminPasswordAuthVerifyMutation>(
      AdminPasswordAuthVerifyDocument,
      {
        adminPasswordAuthVerify: {
          login: 'admin@example.com',
        },
      },
    )

    const view = await visitView('/login?token=valid-token')

    const mockCalls = await mocker.waitForCalls()
    expect(mockCalls).toHaveLength(1)

    const username = await view.findByLabelText('Username / Email')

    expect(username).toBeInTheDocument()
    expect(username).toBeDisabled()
    expect(username).toHaveValue('admin@example.com')

    expect(view.getByText('Password')).toBeInTheDocument()
    expect(view.getByText('Sign in')).toBeInTheDocument()

    expect(
      await view.findByText(
        'The token is valid. You are now able to login via password once.',
      ),
    ).toBeInTheDocument()
  })

  it('shows an error message if the token is invalid', async () => {
    mockApplicationConfig({
      user_show_password_login: false,
      auth_saml: true,
    })

    const mocker = mockGraphQLResult<AdminPasswordAuthVerifyMutation>(
      AdminPasswordAuthVerifyDocument,
      {
        adminPasswordAuthVerify: {
          errors: [
            {
              message: 'The token for the admin password login is invalid.',
            },
          ],
        },
      },
    )

    const view = await visitView('/login?token=invalid-token')

    const mockCalls = await mocker.waitForCalls()
    expect(mockCalls).toHaveLength(1)

    expect(view.queryByText('Username / Email')).not.toBeInTheDocument()
    expect(view.queryByText('Password')).not.toBeInTheDocument()
    expect(view.queryByText('Sign in')).not.toBeInTheDocument()

    expect(
      await view.findByText(
        'The token for the admin password login is invalid.',
      ),
    ).toBeInTheDocument()
  })
})
