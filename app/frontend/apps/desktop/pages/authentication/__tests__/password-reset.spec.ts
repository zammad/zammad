// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  mockGraphQLResult,
  waitForGraphQLMockCalls,
} from '#tests/graphql/builders/mocks.ts'
import type { ExtendedRenderResult } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { mockPublicLinksQuery } from '#shared/entities/public-links/graphql/queries/links.mocks.ts'
import type { UserPasswordResetSendMutation } from '#shared/graphql/types.ts'

import { UserPasswordResetSendDocument } from '../graphql/mutations/userPasswordResetSend.api.ts'

const resetPassword = async (view: ExtendedRenderResult, login: string) => {
  await view.events.type(view.getByLabelText('Username / Email'), login)
  await view.events.click(view.getByRole('button', { name: 'Submit' }))
}

const confirmSuccess = async (view: ExtendedRenderResult, login: string) => {
  const apiCalls = await waitForGraphQLMockCalls(UserPasswordResetSendDocument)

  expect(apiCalls.at(-1)?.variables).toEqual({
    username: login,
  })

  expect(
    await view.findByText('The password reset request was successful.'),
  ).toBeInTheDocument()
}

beforeEach(() => {
  mockApplicationConfig({
    user_lost_password: true,
  })
})

it('can reset a password and try again', async () => {
  const publicLinks = [
    {
      title: 'Imprint',
      link: 'https://example.com/imprint',
      description: null,
    },
    {
      title: 'Privacy policy',
      link: 'https://example.com/privacy',
      description: null,
    },
  ]

  mockPublicLinksQuery({
    publicLinks,
  })

  const view = await visitView('/reset-password')

  expect(
    await view.findByRole('button', { name: 'Cancel & Go Back' }),
  ).toBeInTheDocument()

  const [imprint, privacy] = publicLinks

  expect(await view.findByRole('link', { name: imprint.title })).toHaveProperty(
    'href',
    imprint.link,
  )
  expect(await view.findByRole('link', { name: privacy.title })).toHaveProperty(
    'href',
    privacy.link,
  )

  const login = 'admin@example.com'

  await resetPassword(view, login)
  await confirmSuccess(view, login)

  await view.events.click(view.getByRole('button', { name: 'Try again' }))

  await resetPassword(view, login)
  await confirmSuccess(view, login)
})

it('shows an error if reset was unsuccessful', async () => {
  mockPublicLinksQuery({ publicLinks: [] })

  const view = await visitView('/reset-password')

  mockGraphQLResult<UserPasswordResetSendMutation>(
    UserPasswordResetSendDocument,
    {
      userPasswordResetSend: {
        success: false,
        errors: [
          {
            message: 'The password reset request could not be sent',
            field: null,
          },
        ],
      },
    },
  )

  await resetPassword(view, 'admin@example.com')

  expect(
    await view.findByText('The password reset request could not be sent'),
  ).toBeInTheDocument()
})
