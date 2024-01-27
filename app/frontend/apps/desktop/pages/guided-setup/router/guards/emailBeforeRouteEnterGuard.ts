// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'

export const emailBeforeRouteEnterGuard = () => {
  const application = useApplicationStore()

  if (application.config.system_online_service) {
    return '/guided-setup/manual/channels/email-pre-configured'
  }

  return true
}
