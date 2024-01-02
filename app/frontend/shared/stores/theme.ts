// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '#shared/stores/session.ts'
import { defineStore } from 'pinia'
import { readonly, ref, watch } from 'vue'

type AppThemeName = 'dark' | 'light'

const getRoot = () => document.querySelector(':root') as HTMLElement

const getPreferredTheme = (): AppThemeName => {
  return window.matchMedia('(prefers-color-scheme: dark)').matches
    ? 'dark'
    : 'light'
}

const sanitizeTheme = (theme: string): AppThemeName => {
  if (['dark', 'light'].includes(theme)) return theme as AppThemeName
  return getPreferredTheme()
}

const getDOMTheme = () => {
  const { theme } = getRoot().dataset
  return theme ? sanitizeTheme(theme) : getPreferredTheme()
}

const saveDOMTheme = (theme: AppThemeName) => {
  getRoot().dataset.theme = theme
}

export const useAppTheme = defineStore('theme', () => {
  const session = useSessionStore()

  const getStoredTheme = () =>
    session.user?.preferences?.theme as AppThemeName | undefined

  const storeTheme = async (newTheme: AppThemeName) => {
    // TODO save preferences via API
    console.log('storeTheme', newTheme)
  }

  // the value is changed lated based on the stored theme
  const theme = ref<AppThemeName>('light')

  function saveTheme(newTheme: AppThemeName, persistent: true): Promise<void>
  function saveTheme(newTheme: AppThemeName, persistent: false): void
  function saveTheme(
    newTheme: AppThemeName,
    persistent: boolean,
  ): Promise<void> | void
  // eslint-disable-next-line func-style
  function saveTheme(newTheme: AppThemeName, persistent: boolean) {
    const sanitizedTheme = sanitizeTheme(newTheme)
    theme.value = sanitizedTheme
    saveDOMTheme(sanitizedTheme)
    if (persistent) {
      return storeTheme(sanitizedTheme)
    }
  }

  function toggleTheme(persistent: false): void
  function toggleTheme(persistent: true): Promise<void>
  function toggleTheme(persistent: boolean): Promise<void> | void
  // eslint-disable-next-line func-style
  function toggleTheme(persistent: boolean) {
    const newTheme = theme.value === 'dark' ? 'light' : 'dark'
    return saveTheme(newTheme, persistent)
  }

  // sync theme in case HTML value was not up-to-date when we loaded user preferences
  const syncTheme = () => {
    const domTheme = getDOMTheme()
    if (domTheme !== theme.value) {
      saveDOMTheme(theme.value)
    }
  }

  const storedTheme = getStoredTheme()

  saveTheme(storedTheme || getDOMTheme(), false)

  window
    .matchMedia('(prefers-color-scheme: dark)')
    .addEventListener('change', () => {
      // don't override preferred theme if user has already selected one
      const theme = getStoredTheme() || getPreferredTheme()
      saveTheme(theme, false)
    })

  // in case user changes the theme in another tab
  watch(
    () => getStoredTheme(),
    (newTheme) => {
      if (newTheme && theme.value !== newTheme) {
        saveTheme(newTheme, false)
      }
    },
  )

  return {
    theme: readonly(theme),
    toggleTheme,
    syncTheme,
  }
})
