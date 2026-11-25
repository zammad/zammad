// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
    const mockerUserCurrentAppearanceUpdate = mockUserCurrentAppearanceMutation({
      userCurrentAppearance: {
        success: true,
      },
    })

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
    const mockerUserCurrentAppearanceUpdate = mockUserCurrentAppearanceMutation({
      userCurrentAppearance: {
        errors: [
          {
            message: 'Failed to update.',
          },
        ],
      },
    })

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

  describe('flipTheme', () => {
    const appearanceSaved = { userCurrentAppearance: { success: true } }
    const appearanceFailed = {
      userCurrentAppearance: { errors: [{ message: 'Failed to update.' }] },
    }

    // The system preference is read when the store is created.
    const setupStore = (system: EnumAppearanceTheme, theme?: EnumAppearanceTheme) => {
      setActivePinia(createPinia())
      mockMediaTheme(system)
      mockUserTheme(theme)
      mockUserCurrentAppearanceMutation(appearanceSaved)

      return useThemeStore()
    }

    it.each([
      [EnumAppearanceTheme.Light, EnumAppearanceTheme.Dark],
      [EnumAppearanceTheme.Dark, EnumAppearanceTheme.Light],
    ])('switches from following a %s system to the opposite and back', async (system, opposite) => {
      const themeStore = setupStore(system)

      await themeStore.flipTheme()
      expect(themeStore.currentTheme).toBe(opposite)

      await themeStore.flipTheme()
      expect(themeStore.currentTheme).toBe(EnumAppearanceTheme.Auto)
    })

    it.each([
      [EnumAppearanceTheme.Light, EnumAppearanceTheme.Dark],
      [EnumAppearanceTheme.Dark, EnumAppearanceTheme.Light],
    ])('switches from an explicit %s to the opposite and back', async (theme, opposite) => {
      const themeStore = setupStore(EnumAppearanceTheme.Light, theme)

      await themeStore.flipTheme()
      expect(themeStore.currentTheme).toBe(opposite)

      await themeStore.flipTheme()
      expect(themeStore.currentTheme).toBe(theme)
    })

    it('starts over after the appearance was changed another way', async () => {
      const themeStore = setupStore(EnumAppearanceTheme.Light)

      await themeStore.flipTheme()
      await themeStore.updateTheme(EnumAppearanceTheme.Light)
      await flushPromises()

      await themeStore.flipTheme()
      expect(themeStore.currentTheme).toBe(EnumAppearanceTheme.Dark)

      await themeStore.flipTheme()
      expect(themeStore.currentTheme).toBe(EnumAppearanceTheme.Light)
    })

    it('ignores a call while the appearance is being saved', async () => {
      const themeStore = setupStore(EnumAppearanceTheme.Light)

      await themeStore.flipTheme()

      let finishSave = () => {}

      mockUserCurrentAppearanceMutation(
        () =>
          new Promise((resolve) => {
            finishSave = () => resolve(appearanceFailed)
          }),
      )

      const switchBack = themeStore.flipTheme()
      expect(themeStore.savingTheme).toBe(true)

      await themeStore.flipTheme()

      finishSave()
      await switchBack
      expect(themeStore.currentTheme).toBe(EnumAppearanceTheme.Dark)

      mockUserCurrentAppearanceMutation(appearanceSaved)

      await themeStore.flipTheme()
      expect(themeStore.currentTheme).toBe(EnumAppearanceTheme.Auto)
    })

    it('remembers nothing from a switch that could not be saved', async () => {
      const themeStore = setupStore(EnumAppearanceTheme.Light)

      mockUserCurrentAppearanceMutation(appearanceFailed)
      await themeStore.flipTheme()
      expect(themeStore.currentTheme).toBe(EnumAppearanceTheme.Auto)

      mockUserCurrentAppearanceMutation(appearanceSaved)
      await themeStore.flipTheme()
      expect(themeStore.currentTheme).toBe(EnumAppearanceTheme.Dark)
    })

    it('keeps the setting to restore when switching back could not be saved', async () => {
      const themeStore = setupStore(EnumAppearanceTheme.Light)

      await themeStore.flipTheme()

      mockUserCurrentAppearanceMutation(appearanceFailed)
      await themeStore.flipTheme()
      expect(themeStore.currentTheme).toBe(EnumAppearanceTheme.Dark)

      mockUserCurrentAppearanceMutation(appearanceSaved)
      await themeStore.flipTheme()
      expect(themeStore.currentTheme).toBe(EnumAppearanceTheme.Auto)
    })
  })

  describe('isDarkMode', () => {
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
