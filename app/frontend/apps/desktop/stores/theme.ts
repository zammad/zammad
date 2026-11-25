// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

export const useThemeStore = defineStore(
  'theme',
  () => {
    const session = useSessionStore()

    const savingTheme = ref(false)

    const setThemeMutation = new MutationHandler(useUserCurrentAppearanceMutation(), {
      errorNotificationMessage: __('The appearance could not be updated.'),
    })

    const saveTheme = (newTheme: AppThemeName) => {
      const sanitizedTheme = sanitizeTheme(newTheme)
      saveDOMTheme(sanitizedTheme)
    }

    const setTheme = async (theme: string) => {
      const oldTheme = session.user?.preferences?.theme

      session.setUserPreference('theme', theme)

      return setThemeMutation.send({ theme: theme as EnumAppearanceTheme }).catch(() => {
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
      if (value === session.user?.preferences?.theme || savingTheme.value) return

      savingTheme.value = true

      try {
        await setTheme(value)
      } finally {
        savingTheme.value = false
      }
    }

    // The setting the next flip restores, as long as the appearance is not changed another way.
    let themeBeforeFlip: EnumAppearanceTheme | undefined
    let isFlipping = false

    /**
     * Switches to the explicit opposite of what is shown, and back to the setting before on the
     *   next call: following the system, or the explicit choice the user had made.
     */
    const flipTheme = async () => {
      if (savingTheme.value) return

      const previousTheme = currentTheme.value
      const targetTheme =
        themeBeforeFlip ?? (isDarkMode.value ? EnumAppearanceTheme.Light : EnumAppearanceTheme.Dark)

      isFlipping = true

      try {
        await updateTheme(targetTheme)
      } finally {
        isFlipping = false
      }

      // A failed save is rolled back by the store, the flip then did not happen.
      if (currentTheme.value !== targetTheme) return

      themeBeforeFlip = themeBeforeFlip ? undefined : previousTheme
    }

    // sync theme in case HTML value was not up-to-date when we loaded user preferences
    const syncTheme = () => {
      if (currentTheme.value !== EnumAppearanceTheme.Auto) return saveDOMTheme(currentTheme.value)
      const theme = getPreferredTheme()
      saveDOMTheme(theme)
    }

    // Update based on global system level preference
    watch(preferredColorScheme, (newTheme) => {
      const theme = (currentTheme.value as AppThemeName) || newTheme
      saveTheme(theme)
    })

    // in case user changes the theme in another tab, or store is recreated after logout
    watch(
      () => currentTheme.value,
      (newTheme) => {
        if (!isFlipping) themeBeforeFlip = undefined
        if (newTheme) saveTheme(newTheme as AppThemeName)
      },
    )

    return {
      savingTheme,
      currentTheme,
      isDarkMode,
      updateTheme,
      flipTheme,
      syncTheme,
    }
  },
  {
    requiresAuth: false,
  },
)

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useThemeStore, import.meta.hot))
}
