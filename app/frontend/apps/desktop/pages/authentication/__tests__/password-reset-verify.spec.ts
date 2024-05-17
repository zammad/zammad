// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  getTestRouter,
  type ExtendedRenderResult,
} from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { mockPublicLinksQuery } from '#shared/entities/public-links/graphql/queries/links.mocks.ts'

import { waitForUserPasswordResetUpdateMutationCalls } from '../graphql/mutations/userPasswordResetUpdate.mocks.ts'
import { mockUserPasswordResetVerifyMutation } from '../graphql/mutations/userPasswordResetVerify.mocks.ts'

const updatePassword = async (
  view: ExtendedRenderResult,
  oldPassword: string,
  newPassword: string,
) => {
  await view.events.type(await view.findByLabelText('Password'), oldPassword)
  await view.events.type(
    await view.findByLabelText('Confirm password'),
    newPassword,
  )
  await view.events.click(view.getByRole('button', { name: 'Submit' }))
}

const confirmSuccess = async (view: ExtendedRenderResult, password: string) => {
  const calls = await waitForUserPasswordResetUpdateMutationCalls()
  expect(calls.at(-1)?.variables).toEqual({
    token: '123',
    password,
  })

  expect(
    await view.findByText('Woo hoo! Your password has been changed!'),
  ).toBeInTheDocument()
}

beforeEach(() => {
  mockApplicationConfig({
    user_lost_password: true,
  })
  mockPublicLinksQuery({ publicLinks: [] })
})

it('can update a password', async () => {
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
  mockUserPasswordResetVerifyMutation({
    userPasswordResetVerify: {
      success: true,
      errors: null,
    },
  })

  const view = await visitView('/reset-password/verify/123')

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

  await updatePassword(view, 'password', 'password')
  await confirmSuccess(view, 'password')

  await vi.waitFor(() => {
    expect(getTestRouter().currentRoute.value.name).toBe('Login')
  })
})

it('expects passwords to be equal', async () => {
  mockUserPasswordResetVerifyMutation({
    userPasswordResetVerify: {
      success: true,
      errors: null,
    },
  })

  const view = await visitView('/reset-password/verify/123')

  await updatePassword(view, 'password', 'password123')

  expect(
    await view.findByText(
      "This field doesn't correspond to the expected value.",
    ),
  ).toBeInTheDocument()
})

it('shows an error if reset was unsuccessful', async () => {
  mockUserPasswordResetVerifyMutation({
    userPasswordResetVerify: {
      success: false,
      errors: [{ message: 'The provided token is invalid.', field: null }],
    },
  })

  const view = await visitView('/reset-password/verify/123')

  expect(
    await view.findByText('The provided token is invalid.'),
  ).toBeInTheDocument()
  expect(view.queryByLabelText('Password')).not.toBeInTheDocument()
})

it('shows an error if no token is provided', async () => {
  const view = await visitView('/reset-password/verify')

  expect(
    await view.findByText(
      'The token could not be verified. Please contact your administrator.',
    ),
  ).toBeInTheDocument()
  expect(view.queryByLabelText('Password')).not.toBeInTheDocument()
})
