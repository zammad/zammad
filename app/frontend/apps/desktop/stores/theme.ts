// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { usePreferredColorScheme } from '@vueuse/core'
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
  const root = getRoot()

  root.dataset.theme = theme
  root.style.colorScheme = theme
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

  const currentTheme = computed<EnumAppearanceTheme>(
    () => session.user?.preferences?.theme || EnumAppearanceTheme.Auto,
  )

  const preferredColorScheme = usePreferredColorScheme()

  const isDarkMode = computed(() => {
    if (currentTheme.value === EnumAppearanceTheme.Auto) {
      return preferredColorScheme.value === 'no-preference'
        ? false // if no system preference, default to light mode
        : preferredColorScheme.value === EnumAppearanceTheme.Dark
    }
    return currentTheme.value === EnumAppearanceTheme.Dark
  })

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
  watch(preferredColorScheme, (newTheme) => {
    const theme = (currentTheme.value as AppThemeName) || newTheme
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
    preferredColorScheme,
    currentTheme,
    isDarkMode,
    updateTheme,
    syncTheme,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useThemeStore, import.meta.hot))
}
