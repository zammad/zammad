// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia, storeToRefs } from 'pinia'

import { mockMediaTheme } from '#tests/support/mock-mediaTheme.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { EnumAppearanceTheme } from '#shared/graphql/types.ts'

import { mockUserCurrentAppearanceMutation } from '#desktop/pages/personal-setting/graphql/mutations/userCurrentAppearance.mocks.ts'
import { useThemeStore } from '#desktop/stores/theme.ts'

//  :TODO mock media theme does not update preferredColorScheme preferable without module mocking
// vi.mock('@vueuse/core', async () => {
//   const mod =
//     await vi.importActual<typeof import('@vueuse/core')>('@vueuse/core')
//
//   return {
//     ...mod,
//     usePreferredColorScheme: () => currentTheme,
//   }
// })

const mockUserTheme = (theme: string | undefined) => {
  mockUserCurrent({
    preferences: {
      theme,
    },
  })
}

const getRoot = () => document.querySelector(':root') as HTMLElement

const haveDOMTheme = (theme: string | undefined) => {
  const root = getRoot()

  if (!theme) {
    root.removeAttribute('data-theme')
    root.style.colorScheme = 'normal'
  } else {
    root.dataset.theme = theme
    root.style.colorScheme = theme
  }
}

const getDOMTheme = () => getRoot().dataset.theme

const getDOMColorScheme = () => getRoot().style.colorScheme

describe('useThemeStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mockUserCurrent({
      lastname: 'Doe',
      firstname: 'John',
      preferences: {},
    })

    const { syncTheme } = useThemeStore()
    syncTheme()

    haveDOMTheme(undefined)
    mockMediaTheme(EnumAppearanceTheme.Light)
  })

  it('should fallback to auto when no theme present', () => {
    const { currentTheme } = useThemeStore()

    expect(currentTheme).toBe(EnumAppearanceTheme.Auto)
  })

  it('changes app theme', async () => {
    const mockerUserCurrentAppearanceUpdate = mockUserCurrentAppearanceMutation(
      {
        userCurrentAppearance: {
          success: true,
        },
      },
    )

    const themeStore = useThemeStore()
    const { updateTheme } = themeStore
    const { currentTheme, savingTheme } = storeToRefs(themeStore)

    await updateTheme(EnumAppearanceTheme.Dark)

    expect(currentTheme.value).toBe(EnumAppearanceTheme.Dark)

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

    const themeStore = useThemeStore()
    const { updateTheme } = themeStore
    const { currentTheme, savingTheme } = storeToRefs(themeStore)

    await updateTheme(EnumAppearanceTheme.Dark)

    expect(currentTheme.value).toBe(EnumAppearanceTheme.Auto)

    const mockCalls = await mockerUserCurrentAppearanceUpdate.waitForCalls()
    expect(mockCalls).toHaveLength(1)

    await flushPromises()

    expect(savingTheme.value).toBe(false)
    expect(currentTheme.value).toBe(EnumAppearanceTheme.Auto)
  })

  it('when user has no theme preference, takes from media', () => {
    const { syncTheme } = useThemeStore()
    syncTheme()

    const { currentTheme } = useThemeStore()

    expect(currentTheme).toBe('auto')
  })

  it("changes in media don't affect theme", async () => {
    mockUserTheme(EnumAppearanceTheme.Dark)
    mockMediaTheme(EnumAppearanceTheme.Dark)

    const { syncTheme, currentTheme } = useThemeStore()
    syncTheme()

    expect(currentTheme).toBe(EnumAppearanceTheme.Dark)
    expect(getDOMTheme()).toBe(EnumAppearanceTheme.Dark)
    expect(getDOMColorScheme()).toBe(EnumAppearanceTheme.Dark)

    mockMediaTheme(EnumAppearanceTheme.Light)
    // addEventListener.mock?.calls?.[0][1]()

    expect(currentTheme).toBe(EnumAppearanceTheme.Dark)
    expect(getDOMTheme()).toBe(EnumAppearanceTheme.Dark)
    expect(getDOMColorScheme()).toBe(EnumAppearanceTheme.Dark)
  })

  describe('isDarkMode', () => {
    it.todo('returns true when user prefers dark media theme', async () => {
      // :TODO mock media theme does not update preferredColorScheme
      mockMediaTheme(EnumAppearanceTheme.Dark)

      const { isDarkMode } = useThemeStore()

      expect(isDarkMode).toBe(true)
    })

    it('returns false when user prefers light media theme', async () => {
      mockMediaTheme(EnumAppearanceTheme.Light)

      const { isDarkMode } = useThemeStore()

      expect(isDarkMode).toBe(false)
    })

    it('returns true when user has dark theme active', async () => {
      mockUserTheme(EnumAppearanceTheme.Dark) // has precedence
      mockMediaTheme(EnumAppearanceTheme.Light)

      const { isDarkMode } = useThemeStore()

      expect(isDarkMode).toBe(true)
    })

    it('returns false when user prefers light media theme', async () => {
      mockUserTheme(EnumAppearanceTheme.Light) // has precedence
      mockMediaTheme(EnumAppearanceTheme.Dark)

      const { isDarkMode } = useThemeStore()

      expect(isDarkMode).toBe(false)
    })
  })
})
