// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '#tests/support/mock-graphql-api.ts'

import securityKeys from '#shared/entities/two-factor/plugins/security-keys.ts'
import type {
  TwoFactorPlugin,
  TwoFactorSetupResult,
} from '#shared/entities/two-factor/types.ts'
import { LoginDocument } from '#shared/graphql/mutations/login.api.ts'
import { TwoFactorMethodInitiateAuthenticationDocument } from '#shared/graphql/mutations/twoFactorMethodInitiateAuthentication.api.ts'
import { ApplicationConfigDocument } from '#shared/graphql/queries/applicationConfig.api.ts'
import { ConfigUpdatesDocument } from '#shared/graphql/subscriptions/configUpdates.api.ts'
import type { TwoFactorMethodInitiateAuthenticationMutation } from '#shared/graphql/types.ts'
import { createDeferred } from '#shared/utils/helpers.ts'

import LoginTwoFactor from '../LoginTwoFactor.vue'

const prepareInitialData = (
  data: TwoFactorMethodInitiateAuthenticationMutation['twoFactorMethodInitiateAuthentication'],
) => {
  mockGraphQLApi(TwoFactorMethodInitiateAuthenticationDocument).willResolve({
    twoFactorMethodInitiateAuthentication: {
      initiationData: null,
      errors: null,
      ...data,
    },
  })
}

const loginWillResolve = () => {
  mockGraphQLApi(ApplicationConfigDocument).willResolve({
    applicationConfig: [],
  })
  mockGraphQLSubscription(ConfigUpdatesDocument)
  mockGraphQLApi(LoginDocument).willResolve({
    login: {
      session: {
        id: '1',
        afterAuth: null,
      },
      errors: null,
      twoFactorRequired: null,
    },
  })
}

const renderTwoFactor = (twoFactor: TwoFactorPlugin) => {
  return renderComponent(LoginTwoFactor, {
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
}

describe('non-form two factor', () => {
  it('shows an error if initiated method returns errors', async () => {
    const error = 'Backend cannot handle request right now!'
    prepareInitialData({
      errors: [{ message: error }],
    })

    const view = renderTwoFactor({
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup: () => Promise.resolve({ success: true }),
      },
    })

    await expect(view.findByText(error)).resolves.toBeInTheDocument()
  })

  it('shows an error if there is no initial data', async () => {
    prepareInitialData(null)

    const view = renderTwoFactor({
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup: () => Promise.resolve({ success: true }),
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

    const view = renderTwoFactor({
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup: () => Promise.resolve({ success: false, error }),
      },
    })

    await expect(view.findByText(error)).resolves.toBeInTheDocument()
  })

  it('shows a loader when setup is in progress', async () => {
    const { promise, resolve } = createDeferred<TwoFactorSetupResult>()
    prepareInitialData({
      initiationData: { foo: 'bar' },
    })
    loginWillResolve()

    const view = renderTwoFactor({
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup: () => promise,
      },
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

    const view = renderTwoFactor({
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

    const view = renderTwoFactor({
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup: () => Promise.resolve({ success: false, error }),
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

    const setup = vi.fn().mockResolvedValue({ success: false, error })

    const view = renderTwoFactor({
      ...securityKeys,
      loginOptions: {
        ...securityKeys.loginOptions,
        setup,
      },
    })

    await expect(view.findByText(error)).resolves.toBeInTheDocument()

    setup.mockResolvedValueOnce({ success: false, error: 'New Error!' })

    await view.events.click(view.getByRole('button', { name: 'Retry' }))

    await expect(view.findByText('New Error!')).resolves.toBeInTheDocument()
  })
})
