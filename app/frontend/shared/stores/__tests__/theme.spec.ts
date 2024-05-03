// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

// mounted makes store to reinitiate on each test
import { mounted } from '#tests/support/components/mounted.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { nextTick } from 'vue'
import { useAppTheme } from '../theme.ts'

const haveUserPreference = (theme: string | undefined) => {
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
      matches: !!(rule === '(prefers-color-scheme: dark)' && theme === 'dark'),
      addEventListener,
    }) as any
}

describe('theme is initiated correctly', () => {
  beforeEach(() => {
    haveDOMTheme(undefined)
    haveMediaTheme('light')
  })

  describe("when user doesn't have a preference", () => {
    beforeEach(() => {
      haveUserPreference(undefined)
    })

    it('when DOM is present, takes from DOM', () => {
      haveMediaTheme('light')
      haveDOMTheme('dark')

      const appTheme = mounted(() => useAppTheme())
      expect(appTheme.theme).toBe('dark')
      expect(getDOMTheme()).toBe('dark')
    })

    it('when DOM is not present, takes from media if light', () => {
      haveMediaTheme('light')
      haveDOMTheme(undefined)

      const appTheme = mounted(() => useAppTheme())
      expect(appTheme.theme).toBe('light')
      expect(getDOMTheme()).toBe('light')
    })

    it('when DOM is not present, takes from media if dark', () => {
      haveMediaTheme('dark')
      haveDOMTheme(undefined)

      const appTheme = mounted(() => useAppTheme())
      expect(appTheme.theme).toBe('dark')
      expect(getDOMTheme()).toBe('dark')
    })

    it('when media changes, update theme', async () => {
      haveMediaTheme('dark')

      const appTheme = mounted(() => useAppTheme())
      expect(appTheme.theme).toBe('dark')
      expect(getDOMTheme()).toBe('dark')

      haveMediaTheme('light')
      addEventListener.mock.calls[0][1]()

      expect(appTheme.theme).toBe('light')
      expect(getDOMTheme()).toBe('light')
    })
  })

  describe('when user has a preference', () => {
    it('when user has dark theme enabled, but DOM and media are light, takes from user preference', () => {
      haveUserPreference('dark')
      haveMediaTheme('light')
      haveDOMTheme('light')

      const appTheme = mounted(() => useAppTheme())
      expect(appTheme.theme).toBe('dark')
      expect(getDOMTheme()).toBe('dark')
    })

    it('when user has light theme enabled, but DOM and media are dark, takes from user preference', () => {
      haveUserPreference('light')
      haveMediaTheme('dark')
      haveDOMTheme('dark')

      const appTheme = mounted(() => useAppTheme())
      expect(appTheme.theme).toBe('light')
      expect(getDOMTheme()).toBe('light')
    })

    it('updates theme when account is changed', async () => {
      haveUserPreference('light')

      const appTheme = mounted(() => useAppTheme())

      expect(appTheme.theme).toBe('light')
      expect(getDOMTheme()).toBe('light')

      haveUserPreference('dark')

      await nextTick()

      expect(appTheme.theme).toBe('dark')
      expect(getDOMTheme()).toBe('dark')
    })

    it('can toggle them from the outside', () => {
      haveUserPreference('light')

      const appTheme = mounted(() => useAppTheme())

      expect(appTheme.theme).toBe('light')
      expect(getDOMTheme()).toBe('light')

      appTheme.toggleTheme(false)

      expect(appTheme.theme).toBe('dark')
      expect(getDOMTheme()).toBe('dark')
    })

    it("changes in media don't affect theme", async () => {
      haveUserPreference('dark')
      haveMediaTheme('dark')

      const appTheme = mounted(() => useAppTheme())
      expect(appTheme.theme).toBe('dark')
      expect(getDOMTheme()).toBe('dark')

      haveMediaTheme('light')
      addEventListener.mock.calls[0][1]()

      expect(appTheme.theme).toBe('dark')
      expect(getDOMTheme()).toBe('dark')
    })

    // TODO: when saveTheme implements API call
    it.todo('stored the new value in user preferences when theme is toggled')
  })
})
