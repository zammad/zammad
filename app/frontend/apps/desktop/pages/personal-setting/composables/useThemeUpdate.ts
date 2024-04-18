// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { EnumAppearanceTheme } from '#shared/graphql/types.ts'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useAccountAppearanceMutation } from '../graphql/mutations/accountAppearance.api.ts'

export const useThemeUpdate = (showSuccessNotification = false) => {
  const setThemeMutation = new MutationHandler(useAccountAppearanceMutation(), {
    errorNotificationMessage: __('The appearance could not be updated.'),
  })

  const savingTheme = ref(false)

  const session = useSessionStore()
  const { notify } = useNotifications()

  const setTheme = async (theme: string) => {
    const oldTheme = session.user?.preferences?.theme

    // Do it before the mutation to avoid a laggy UI.
    session.setUserPreference('theme', theme)

    return setThemeMutation
      .send({ theme: theme as EnumAppearanceTheme })
      .catch(() => {
        session.setUserPreference('theme', oldTheme)
      })
  }

  const currentTheme = computed({
    get: () => session.user?.preferences?.theme || 'auto',
    set: (value: EnumAppearanceTheme) => {
      if (value === session.user?.preferences?.theme || savingTheme.value) {
        return
      }

      savingTheme.value = true
      setTheme(value)
        .then(() => {
          if (showSuccessNotification) {
            notify({
              id: 'theme-update',
              message: __('Profile appearance updated successfully.'),
              type: NotificationTypes.Success,
            })
          }
        })
        .finally(() => {
          savingTheme.value = false
        })
    },
  })

  return {
    currentTheme,
    savingTheme,
    setTheme,
  }
}
