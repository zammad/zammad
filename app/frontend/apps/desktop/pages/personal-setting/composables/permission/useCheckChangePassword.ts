// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

export const useCheckChangePassword = () => {
  const { config } = useApplicationStore()
  const { hasPermission } = useSessionStore()

  const canChangePassword = computed(
    () => config.user_show_password_login || hasPermission('admin.*'),
  )

  return {
    canChangePassword,
  }
}
