// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'

import { EnumAppearanceTheme } from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useUserCurrentAppearanceMutation } from '#desktop/pages/personal-setting/graphql/mutations/userCurrentAppearance.api.ts'

type AppThemeName = EnumAppearanceTheme.Light | EnumAppearanceTheme.Dark

const getRoot = () => document.querySelector(':root') as HTMLElement

const getPreferredTheme = (): AppThemeName => {
  return window.matchMedia('(prefers-color-scheme: dark)').matches
    ? EnumAppearanceTheme.Dark
    : EnumAppearanceTheme.Light
}

const sanitizeTheme = (theme: string): AppThemeName => {
  if (['dark', 'light'].includes(theme)) return theme as AppThemeName
  return getPreferredTheme()
}

const saveDOMTheme = (theme: AppThemeName) => {
  getRoot().dataset.theme = theme
}

export const useThemeStore = defineStore('theme', () => {
  const session = useSessionStore()

  const savingTheme = ref(false)

  const setThemeMutation = new MutationHandler(
    useUserCurrentAppearanceMutation(),
    {
      errorNotificationMessage: __('The appearance could not be updated.'),
    },
  )

  const saveTheme = (newTheme: AppThemeName) => {
    const sanitizedTheme = sanitizeTheme(newTheme)
    saveDOMTheme(sanitizedTheme)
  }

  const setTheme = async (theme: string) => {
    const oldTheme = session.user?.preferences?.theme

    session.setUserPreference('theme', theme)

    return setThemeMutation
      .send({ theme: theme as EnumAppearanceTheme })
      .catch(() => {
        session.setUserPreference('theme', oldTheme)
      })
  }

  const currentTheme = computed(
    () => session.user?.preferences?.theme || 'auto',
  )

  const isDarkMode = computed(
    () => sanitizeTheme(currentTheme.value) === 'dark',
  )

  const updateTheme = async (value: EnumAppearanceTheme) => {
    try {
      if (value === session.user?.preferences?.theme || savingTheme.value)
        return

      savingTheme.value = true

      await setTheme(value)
    } finally {
      savingTheme.value = false
    }
  }

  // sync theme in case HTML value was not up-to-date when we loaded user preferences
  const syncTheme = () => {
    if (currentTheme.value !== 'auto') return saveDOMTheme(currentTheme.value)
    const theme = getPreferredTheme()
    saveDOMTheme(theme)
  }

  // Update based on global system level preference
  window
    .matchMedia('(prefers-color-scheme: dark)')
    .addEventListener('change', () => {
      // don't override preferred theme if user has already selected one
      const theme = (currentTheme.value as AppThemeName) || getPreferredTheme()
      saveTheme(theme)
    })

  // in case user changes the theme in another tab
  watch(
    () => currentTheme.value,
    (newTheme) => {
      if (newTheme) {
        saveTheme(newTheme as AppThemeName)
      }
    },
  )

  return {
    savingTheme,
    currentTheme,
    isDarkMode,
    updateTheme,
    syncTheme,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useThemeStore, import.meta.hot))
}
