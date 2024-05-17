// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import {
  mockGraphQLResult,
  waitForGraphQLMockCalls,
} from '#tests/graphql/builders/mocks.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import securityKeys from '#shared/entities/two-factor/plugins/security-keys.ts'
import type {
  TwoFactorPlugin,
  TwoFactorSetupResult,
} from '#shared/entities/two-factor/types.ts'
import { TwoFactorMethodInitiateAuthenticationDocument } from '#shared/graphql/mutations/twoFactorMethodInitiateAuthentication.api.ts'
import type { TwoFactorMethodInitiateAuthenticationMutation } from '#shared/graphql/types.ts'
import { createDeferred } from '#shared/utils/helpers.ts'

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

const securitySuccess = () => {
  return {
    success: true,
    payload: {
      challenge: 'publicKey.challenge',
      credential: 'publicKeyCredential',
    },
  }
}

describe('non-form two factor', () => {
  mockApplicationConfig({})

  it('shows an error if initiated method returns errors', async () => {
    const error = 'Backend cannot handle request right now!'
    prepareInitialData({
      errors: [{ message: error }],
    })

    const view = await renderTwoFactor({
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup: () => Promise.resolve(securitySuccess()),
      },
    })

    await expect(view.findByText(error)).resolves.toBeInTheDocument()
  })

  it('shows an error if there is no initial data', async () => {
    prepareInitialData(null)

    const view = await renderTwoFactor({
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup: () => Promise.resolve(securitySuccess()),
      },
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
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup: () => Promise.resolve({ success: false, retry: false, error }),
      },
    })

    await expect(view.findByText(error)).resolves.toBeInTheDocument()
  })

  it('shows a loader when setup is in progress', async () => {
    const { promise, resolve } = createDeferred<TwoFactorSetupResult>()
    prepareInitialData({
      initiationData: { foo: 'bar' },
    })

    const view = await renderTwoFactor({
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup: () => promise,
      },
    })

    await expect(view.findByRole('status')).resolves.toBeInTheDocument()
    resolve(securitySuccess())

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
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup: () => Promise.resolve({ success: false, retry: false, error }),
      },
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
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup: () => Promise.resolve({ success: false, retry: true, error }),
      },
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

    const setup = vi
      .fn()
      .mockResolvedValue({ success: false, retry: true, error })

    const view = await renderTwoFactor({
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup,
      },
    })

    await expect(view.findByText(error)).resolves.toBeInTheDocument()

    setup.mockResolvedValueOnce({
      success: false,
      retry: true,
      error: 'New Error!',
    })

    await view.events.click(view.getByRole('button', { name: 'Retry' }))

    await expect(view.findByText('New Error!')).resolves.toBeInTheDocument()
  })
})
