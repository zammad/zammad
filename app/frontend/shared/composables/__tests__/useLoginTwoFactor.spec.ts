// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createTestingPinia } from '@pinia/testing'

import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import useLoginTwoFactor from '../authentication/useLoginTwoFactor.ts'

describe('useLoginTwoFactor', () => {
  createTestingPinia({ createSpy: vi.fn })

  it('can update login state', () => {
    const clearErrors = vi.fn()

    const { loginFlow, updateState } = useLoginTwoFactor(clearErrors)

    updateState('2fa')

    expect(clearErrors).toHaveBeenCalledOnce()
    expect(loginFlow.state).toBe('2fa')
  })

  it('can update second factor', () => {
    const clearErrors = vi.fn()

    const { loginFlow, updateSecondFactor } = useLoginTwoFactor(clearErrors)

    updateSecondFactor(EnumTwoFactorAuthenticationMethod.SecurityKeys)

    expect(clearErrors).toHaveBeenCalledOnce()
    expect(loginFlow.twoFactor).toBe(
      EnumTwoFactorAuthenticationMethod.SecurityKeys,
    )
    expect(loginFlow.state).toBe('2fa')
  })

  it('can ask for two-factor authentication', () => {
    const clearErrors = vi.fn()

    const { loginFlow, askTwoFactor } = useLoginTwoFactor(clearErrors)

    const testAllowedMethods = [
      EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
      EnumTwoFactorAuthenticationMethod.SecurityKeys,
    ]

    const testDefaultMethod = EnumTwoFactorAuthenticationMethod.SecurityKeys

    const testCredentials = {
      login: 'foo',
      password: 'bar',
      rememberMe: true,
    }

    askTwoFactor(
      {
        availableTwoFactorAuthenticationMethods: testAllowedMethods,
        defaultTwoFactorAuthenticationMethod: testDefaultMethod,
        recoveryCodesAvailable: true,
      },
      testCredentials,
    )

    expect(clearErrors).toHaveBeenCalledOnce()
    expect(loginFlow.credentials).toEqual(testCredentials)
    expect(loginFlow.recoveryCodesAvailable).toBe(true)
    expect(loginFlow.allowedMethods).toEqual(testAllowedMethods)
    expect(loginFlow.defaultMethod).toEqual(testDefaultMethod)
    expect(loginFlow.twoFactor).toBe(testDefaultMethod)
    expect(loginFlow.state).toBe('2fa')
  })

  it('can filter for allowed two-factor methods', () => {
    const clearErrors = vi.fn()

    const { loginFlow, twoFactorAllowedMethods } =
      useLoginTwoFactor(clearErrors)

    loginFlow.allowedMethods = [
      EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
      'foobar' as EnumTwoFactorAuthenticationMethod,
    ]

    expect(twoFactorAllowedMethods.value).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          name: EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
        }),
      ]),
    )
    expect(twoFactorAllowedMethods.value).toEqual(
      expect.not.arrayContaining([
        expect.objectContaining({
          name: EnumTwoFactorAuthenticationMethod.SecurityKeys,
        }),
      ]),
    )
    expect(twoFactorAllowedMethods.value).toEqual(
      expect.not.arrayContaining([
        expect.objectContaining({
          name: 'foobar',
        }),
      ]),
    )
  })

  it('can return current two-factor method plugin', () => {
    const clearErrors = vi.fn()

    const { loginFlow, twoFactorPlugin } = useLoginTwoFactor(clearErrors)

    loginFlow.twoFactor = EnumTwoFactorAuthenticationMethod.SecurityKeys

    expect(twoFactorPlugin.value).toEqual(
      expect.objectContaining({
        name: EnumTwoFactorAuthenticationMethod.SecurityKeys,
      }),
    )
  })

  it('can tell if there is an alternative login method', () => {
    const clearErrors = vi.fn()

    const { loginFlow, hasAlternativeLoginMethod } =
      useLoginTwoFactor(clearErrors)

    loginFlow.allowedMethods = [
      EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
      EnumTwoFactorAuthenticationMethod.SecurityKeys,
    ]

    expect(hasAlternativeLoginMethod.value).toBe(true)
  })

  it('can go back to previous state in the flow', () => {
    const clearErrors = vi.fn()

    const { loginFlow, goBack } = useLoginTwoFactor(clearErrors)

    loginFlow.state = '2fa-select'

    goBack()

    expect(loginFlow.state).toBe('2fa')
  })

  it('can cancel login and go back to initial step', () => {
    const clearErrors = vi.fn()

    const { loginFlow, cancelAndGoBack } = useLoginTwoFactor(clearErrors)

    cancelAndGoBack()

    expect(loginFlow.state).toBe('credentials')
    expect(loginFlow.credentials).toBeUndefined()
  })

  it('can return current page title', () => {
    const clearErrors = vi.fn()

    useApplicationStore().config.product_name = 'Zammad'

    const { loginFlow, loginPageTitle } = useLoginTwoFactor(clearErrors)

    expect(loginPageTitle.value).toBe('Zammad')

    loginFlow.state = 'recovery-code'

    expect(loginPageTitle.value).toBe('Recovery Code')

    loginFlow.twoFactor = EnumTwoFactorAuthenticationMethod.AuthenticatorApp
    loginFlow.state = '2fa'

    expect(loginPageTitle.value).toBe('Authenticator App')

    loginFlow.state = '2fa-select'

    expect(loginPageTitle.value).toBe('Try Another Method')
  })
})
