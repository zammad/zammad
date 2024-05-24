// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia, storeToRefs } from 'pinia'

import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { EnumAppearanceTheme } from '#shared/graphql/types.ts'

import { mockUserCurrentAppearanceMutation } from '#desktop/pages/personal-setting/graphql/mutations/userCurrentAppearance.mocks.ts'
import { useThemeStore } from '#desktop/stores/theme.ts'

const mockUserTheme = (theme: string | undefined) => {
  mockUserCurrent({
    preferences: {
      theme,
    },
  })
}

const haveDOMTheme = (theme: string | undefined) => {
  const root = document.querySelector(':root') as HTMLElement
  if (!theme) {
    root.removeAttribute('data-theme')
  } else {
    root.dataset.theme = theme
  }
}

const getDOMTheme = () => {
  const root = document.querySelector(':root') as HTMLElement
  return root.dataset.theme
}

const addEventListener = vi.fn()

const haveMediaTheme = (theme: string) => {
  window.matchMedia = (rule) =>
    ({
      matches: rule === '(prefers-color-scheme: dark)' && theme === 'dark',
      addEventListener,
    }) as any
}

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
    haveMediaTheme('light')
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

    const themStore = useThemeStore()
    const { updateTheme } = themStore
    const { currentTheme, savingTheme } = storeToRefs(themStore)

    await updateTheme(EnumAppearanceTheme.Dark)

    expect(currentTheme.value).toBe(EnumAppearanceTheme.Auto)

    const mockCalls = await mockerUserCurrentAppearanceUpdate.waitForCalls()
    expect(mockCalls).toHaveLength(1)

    await flushPromises()

    expect(savingTheme.value).toBe(false)
    expect(currentTheme.value).toBe(EnumAppearanceTheme.Auto)
  })

  // describe('when user has a preference', () => {
  it('when user has no theme preference, takes from media', () => {
    const { syncTheme } = useThemeStore()
    syncTheme()

    const { currentTheme } = useThemeStore()

    expect(currentTheme).toBe('auto')
  })

  it("changes in media don't affect theme", async () => {
    mockUserTheme(EnumAppearanceTheme.Dark)
    haveMediaTheme(EnumAppearanceTheme.Dark)

    const { syncTheme, currentTheme } = useThemeStore()
    syncTheme()

    expect(currentTheme).toBe(EnumAppearanceTheme.Dark)
    expect(getDOMTheme()).toBe(EnumAppearanceTheme.Dark)

    haveMediaTheme(EnumAppearanceTheme.Light)
    addEventListener.mock.calls[0][1]()

    expect(currentTheme).toBe(EnumAppearanceTheme.Dark)
    expect(getDOMTheme()).toBe(EnumAppearanceTheme.Dark)
  })
})
