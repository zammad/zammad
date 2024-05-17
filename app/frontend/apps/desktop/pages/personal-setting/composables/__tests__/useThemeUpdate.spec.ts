// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'

import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { EnumAppearanceTheme } from '#shared/graphql/types.ts'

import { mockUserCurrentAppearanceMutation } from '../../graphql/mutations/userCurrentAppearance.mocks.ts'
import { useThemeUpdate } from '../useThemeUpdate.ts'

describe('useThemeUpdate', () => {
  beforeEach(() => {
    mockUserCurrent({
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
    const mockerUserCurrentAppearanceUpdate = mockUserCurrentAppearanceMutation(
      {
        userCurrentAppearance: {
          success: true,
        },
      },
    )

    const { currentTheme, savingTheme } = useThemeUpdate()

    currentTheme.value = EnumAppearanceTheme.Dark
    expect(currentTheme.value).toBe(EnumAppearanceTheme.Dark)

    expect(savingTheme.value).toBe(true)

    const mockCalls = await mockerUserCurrentAppearanceUpdate.waitForCalls()
    expect(mockCalls).toHaveLength(1)

    await flushPromises()
    expect(savingTheme.value).toBe(false)
    expect(currentTheme.value).toBe(EnumAppearanceTheme.Dark)
  })

  it('should change theme value back to old value when update fails', async () => {
    const mockerUserCurrentAppearanceUpdate = mockUserCurrentAppearanceMutation(
      {
        userCurrentAppearance: {
          errors: [
            {
              message: 'Failed to update.',
            },
          ],
        },
      },
    )

    const { currentTheme, savingTheme } = useThemeUpdate()

    currentTheme.value = EnumAppearanceTheme.Dark

    expect(currentTheme.value).toBe(EnumAppearanceTheme.Dark)
    expect(savingTheme.value).toBe(true)

    const mockCalls = await mockerUserCurrentAppearanceUpdate.waitForCalls()
    expect(mockCalls).toHaveLength(1)

    await flushPromises()

    expect(savingTheme.value).toBe(false)
    expect(currentTheme.value).toBe(EnumAppearanceTheme.Auto)
  })
})
