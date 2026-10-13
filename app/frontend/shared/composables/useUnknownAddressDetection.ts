// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { watch } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { navigateTo } from '#shared/utils/navigation.ts'

const NOTIFICATION_ID = 'unknown-fqdn-redirect'

export const useUnknownAddressDetection = () => {
  const application = useApplicationStore()
  const { notify, removeNotification } = useNotifications()

  // The same page on the configured address, or null when the current address is a configured one.
  const getRedirectUrl = (): string | null => {
    const { fqdn, alternative_fqdn: alternativeFqdn, http_type: httpType } = application.config

    // The placeholder FQDN of a fresh installation is not a real address, so there is nothing to redirect to.
    if (!fqdn || fqdn === 'zammad.example.com') return null

    const { protocol, host, pathname, search, hash } = window.location

    const configuredHosts = [fqdn, alternativeFqdn]
      .filter((value): value is string => Boolean(value))
      .map((value) => value.toLowerCase())

    const hostMatches = configuredHosts.includes(host.toLowerCase())
    const protocolMatches = !httpType || protocol === `${httpType}:`

    if (hostMatches && protocolMatches) return null

    const targetProtocol = httpType || protocol.slice(0, -1)

    return `${targetProtocol}://${fqdn}${pathname}${search}${hash}`
  }

  const updateNotification = () => {
    if (!getRedirectUrl()) {
      removeNotification(NOTIFICATION_ID)
      return
    }

    notify({
      id: NOTIFICATION_ID,
      type: NotificationTypes.Warn,
      message: __("This isn't the address Zammad is set up for."),
      persistent: true,
      // Login forms and logout clear all notifications, the warning has to outlive that.
      preserveOnClear: true,
      actionLabel: __('Switch here'),
      // The user may have navigated since the warning appeared, so the target is resolved on click.
      actionCallback: () => {
        const redirectUrl = getRedirectUrl()

        if (redirectUrl) navigateTo(redirectUrl)
      },
    })
  }

  // The config is reloaded on login and logout, so the warning has to follow it.
  watch(
    () => [
      application.config.fqdn,
      application.config.alternative_fqdn,
      application.config.http_type,
    ],
    updateNotification,
    { immediate: true },
  )
}
