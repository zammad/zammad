// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockGraphQLResult } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import type { AdminPasswordAuthSendMutation } from '#shared/graphql/types.ts'
import { AdminPasswordAuthSendDocument } from '../graphql/mutations/adminPasswordAuthSend.api.ts'

describe('requesting a token for the admin password auth', () => {
  mockApplicationConfig({
    user_show_password_login: false,
    auth_github: true,
  })

  it('can request a token for the admin password auth', async () => {
    const view = await visitView('/admin-password-auth')

    const mocker = mockGraphQLResult<AdminPasswordAuthSendMutation>(
      AdminPasswordAuthSendDocument,
      { adminPasswordAuthSend: { success: true } },
    )

    expect(
      await view.findByText('Request password login for admin?'),
    ).toBeInTheDocument()

    const username = view.getByLabelText('Username / Email')
    await view.events.type(username, 'admin@example.com')

    await view.events.click(view.getByRole('button', { name: 'Submit' }))

    const mockCalls = await mocker.waitForCalls()

    expect(mockCalls).toHaveLength(1)

    expect(mockCalls[0].variables).toEqual({
      login: 'admin@example.com',
    })

    expect(
      await view.findByText(
        'Admin password login instructions were sent to your email address.',
      ),
    ).toBeInTheDocument()

    expect(
      view.queryByRole('button', { name: 'Submit' }),
    ).not.toBeInTheDocument()

    expect(
      await view.findByRole('button', { name: 'Retry' }),
    ).toBeInTheDocument()

    expect(
      await view.findByRole('button', { name: 'Cancel & Go Back' }),
    ).toBeInTheDocument()
  })
})
