// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumAppearanceTheme } from '#shared/graphql/types.ts'
import { mockAccount } from '#tests/support/mock-account.ts'
import { flushPromises } from '@vue/test-utils'

import { mockAccountAppearanceMutation } from '../../graphql/mutations/accountAppearance.mocks.ts'
import { useThemeUpdate } from '../useThemeUpdate.ts'

describe('useThemeUpdate', () => {
  beforeEach(() => {
    mockAccount({
      lastname: 'Doe',
      firstname: 'John',
      preferences: {},
    })
  })

  it('should fallback to auto when no theme present', () => {
    const { currentTheme } = useThemeUpdate()

    expect(currentTheme.value).toBe('auto')
  })

  it('should change theme value', async () => {
    const mockerAccountAppearanceUpdate = mockAccountAppearanceMutation({
      accountAppearance: {
        success: true,
      },
    })

    const { currentTheme, savingTheme } = useThemeUpdate()

    currentTheme.value = EnumAppearanceTheme.Dark
    expect(currentTheme.value).toBe(EnumAppearanceTheme.Dark)

    expect(savingTheme.value).toBe(true)

    const mockCalls = await mockerAccountAppearanceUpdate.waitForCalls()
    expect(mockCalls).toHaveLength(1)

    await flushPromises()
    expect(savingTheme.value).toBe(false)
    expect(currentTheme.value).toBe(EnumAppearanceTheme.Dark)
  })

  it('should change theme value back to old value when update fails', async () => {
    const mockerAccountAppearanceUpdate = mockAccountAppearanceMutation({
      accountAppearance: {
        errors: [
          {
            message: 'Failed to update.',
          },
        ],
      },
    })

    const { currentTheme, savingTheme } = useThemeUpdate()

    currentTheme.value = EnumAppearanceTheme.Dark

    expect(currentTheme.value).toBe(EnumAppearanceTheme.Dark)
    expect(savingTheme.value).toBe(true)

    const mockCalls = await mockerAccountAppearanceUpdate.waitForCalls()
    expect(mockCalls).toHaveLength(1)

    await flushPromises()

    expect(savingTheme.value).toBe(false)
    expect(currentTheme.value).toBe(EnumAppearanceTheme.Auto)
  })
})
