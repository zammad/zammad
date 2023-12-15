// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type {
  TwoFactorPlugin,
  TwoFactorSetupResult,
} from '#shared/entities/two-factor/types.ts'
import { TwoFactorMethodInitiateAuthenticationDocument } from '#shared/graphql/mutations/twoFactorMethodInitiateAuthentication.api.ts'
import type { TwoFactorMethodInitiateAuthenticationMutation } from '#shared/graphql/types.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import {
  mockGraphQLResult,
  waitForGraphQLMockCalls,
} from '#tests/graphql/builders/mocks.ts'
import SecurityKeys from '#shared/entities/two-factor/plugins/security_keys.ts'
import { createDeferred } from '#shared/utils/helpers.ts'
import { waitFor } from '@testing-library/vue'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import LoginTwoFactor from '../LoginTwoFactor.vue'

const prepareInitialData = (
  data: TwoFactorMethodInitiateAuthenticationMutation['twoFactorMethodInitiateAuthentication'],
) => {
  mockGraphQLResult<TwoFactorMethodInitiateAuthenticationMutation>(
    TwoFactorMethodInitiateAuthenticationDocument,
    {
      twoFactorMethodInitiateAuthentication: {
        initiationData: null,
        errors: null,
        ...data,
      },
    },
  )
}

const renderTwoFactor = async (twoFactor: TwoFactorPlugin) => {
  const view = renderComponent(LoginTwoFactor, {
    props: {
      credentials: {
        login: 'login',
        password: 'password',
        rememberMe: false,
      },
      twoFactor,
    },
    store: true,
    form: true,
  })

  await waitForGraphQLMockCalls(
    'mutation',
    'twoFactorMethodInitiateAuthentication',
  )

  return view
}

describe('non-form two factor', () => {
  mockApplicationConfig({})

  it('shows an error if initiated method returns errors', async () => {
    const error = 'Backend cannot handle request right now!'
    prepareInitialData({
      errors: [{ message: error }],
    })

    const view = await renderTwoFactor({
      ...SecurityKeys,
      setup: () => Promise.resolve({ success: true }),
    })

    await expect(view.findByText(error)).resolves.toBeInTheDocument()
  })

  it('shows an error if there is no initial data', async () => {
    prepareInitialData(null)

    const view = await renderTwoFactor({
      ...SecurityKeys,
      setup: () => Promise.resolve({ success: true }),
    })

    await expect(
      view.findByText(
        'Two-factor authentication method could not be initiated.',
      ),
    ).resolves.toBeInTheDocument()
  })

  it('shows an error if setup did not succeed', async () => {
    const error = 'Frontend cannot handle request right now!'
    prepareInitialData({
      initiationData: { foo: 'bar' },
    })

    const view = await renderTwoFactor({
      ...SecurityKeys,
      setup: () => Promise.resolve({ success: false, error }),
    })

    await expect(view.findByText(error)).resolves.toBeInTheDocument()
  })

  it('shows a loader when setup is in progress', async () => {
    const { promise, resolve } = createDeferred<TwoFactorSetupResult>()
    prepareInitialData({
      initiationData: { foo: 'bar' },
    })

    const view = await renderTwoFactor({
      ...SecurityKeys,
      setup: () => promise,
    })

    await expect(view.findByRole('status')).resolves.toBeInTheDocument()
    resolve({ success: true })

    await waitFor(() => {
      expect(view.queryByRole('status')).not.toBeInTheDocument()
    })

    expect(
      view.queryByRole('button', { name: 'Retry' }),
      "doesn't have retry button after successful login",
    ).not.toBeInTheDocument()

    expect(view.emitted()).toHaveProperty('finish')
    expect(view.emitted()).not.toHaveProperty('error')
  })

  it("doesn't show retry button if it's disabled", async () => {
    const error = 'Frontend cannot handle request right now!'
    prepareInitialData({
      initiationData: { foo: 'bar' },
    })

    const view = await renderTwoFactor({
      ...SecurityKeys,
      setup: () => Promise.resolve({ success: false, retry: false, error }),
    })

    await expect(view.findByText(error)).resolves.toBeInTheDocument()

    expect(
      view.queryByRole('button', { name: 'Retry' }),
    ).not.toBeInTheDocument()
  })

  it("show retry button if it's not disabled", async () => {
    const error = 'Frontend cannot handle request right now!'
    prepareInitialData({
      initiationData: { foo: 'bar' },
    })

    const view = await renderTwoFactor({
      ...SecurityKeys,
      setup: () => Promise.resolve({ success: false, error }),
    })

    await expect(view.findByText(error)).resolves.toBeInTheDocument()
    await expect(
      view.findByRole('button', { name: 'Retry' }),
    ).resolves.toBeInTheDocument()
  })

  it('retry button calls setup again', async () => {
    const error = 'Frontend cannot handle request right now!'
    prepareInitialData({
      initiationData: { foo: 'bar' },
    })

    const setup = vi.fn().mockResolvedValue({ success: false, error })

    const view = await renderTwoFactor({
      ...SecurityKeys,
      setup,
    })

    await expect(view.findByText(error)).resolves.toBeInTheDocument()

    setup.mockResolvedValueOnce({ success: false, error: 'New Error!' })

    await view.events.click(view.getByRole('button', { name: 'Retry' }))

    await expect(view.findByText('New Error!')).resolves.toBeInTheDocument()
  })
})
