// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope, nextTick, type EffectScope } from 'vue'

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { ConfigList } from '#shared/types/store.ts'
import { navigateTo } from '#shared/utils/navigation.ts'

import { useUnknownAddressDetection } from '../useUnknownAddressDetection.ts'

vi.mock('#shared/utils/navigation.ts')

let scope: EffectScope

const detectUnknownAddress = () => {
  scope = effectScope()
  scope.run(() => useUnknownAddressDetection())
}

const configure = (config: {
  fqdn: string
  alternative_fqdn?: string
  http_type?: 'https' | 'http' | null
}) => {
  mockApplicationConfig({
    fqdn: config.fqdn,
    alternative_fqdn: config.alternative_fqdn ?? '',
    http_type: config.http_type ?? null,
  })
}

describe('useUnknownAddressDetection', () => {
  afterEach(() => {
    scope.stop()
    useNotifications().removeNotification('unknown-fqdn-redirect')
    window.history.replaceState({}, '', '/')
  })

  it('stays silent when the address matches the configured FQDN and HTTP type', () => {
    configure({ fqdn: 'localhost:3000', http_type: 'http' })

    detectUnknownAddress()

    expect(useNotifications().notifications.value).toHaveLength(0)
  })

  it('compares the host case-insensitively', () => {
    configure({ fqdn: 'LOCALHOST:3000', http_type: 'http' })

    detectUnknownAddress()

    expect(useNotifications().notifications.value).toHaveLength(0)
  })

  it('stays silent when the address matches the alternative FQDN', () => {
    configure({ fqdn: 'zammad.org', alternative_fqdn: 'localhost:3000', http_type: 'http' })

    detectUnknownAddress()

    expect(useNotifications().notifications.value).toHaveLength(0)
  })

  it('stays silent for the placeholder FQDN of a fresh installation', () => {
    configure({ fqdn: 'zammad.example.com', http_type: 'https' })

    detectUnknownAddress()

    expect(useNotifications().notifications.value).toHaveLength(0)
  })

  it('stays silent without a configured FQDN', () => {
    configure({ fqdn: '', http_type: 'https' })

    detectUnknownAddress()

    expect(useNotifications().notifications.value).toHaveLength(0)
  })

  it('warns persistently when the host differs', () => {
    configure({ fqdn: 'zammad.org', http_type: 'http' })

    detectUnknownAddress()

    const { notifications } = useNotifications()

    expect(notifications.value).toHaveLength(1)
    expect(notifications.value[0]).toMatchObject({
      id: 'unknown-fqdn-redirect',
      type: 'warn',
      persistent: true,
      message: "This isn't the address Zammad is set up for.",
      actionLabel: 'Switch here',
    })
  })

  it('warns when the HTTP type differs', () => {
    configure({ fqdn: 'localhost:3000', http_type: 'https' })

    detectUnknownAddress()

    expect(useNotifications().notifications.value).toHaveLength(1)
  })

  it('redirects to the same page on the configured address', () => {
    window.history.replaceState({}, '', '/desktop/tickets/1?foo=bar#baz')
    configure({ fqdn: 'zammad.org', http_type: 'https' })

    detectUnknownAddress()

    useNotifications().notifications.value[0].actionCallback?.()

    expect(navigateTo).toHaveBeenCalledWith('https://zammad.org/desktop/tickets/1?foo=bar#baz')
  })

  it('redirects to the page that is current when switching, not when the warning appeared', () => {
    configure({ fqdn: 'zammad.org', http_type: 'https' })

    detectUnknownAddress()

    window.history.replaceState({}, '', '/desktop/tickets/2')

    useNotifications().notifications.value[0].actionCallback?.()

    expect(navigateTo).toHaveBeenCalledWith('https://zammad.org/desktop/tickets/2')
  })

  it('redirects to the primary FQDN when the alternative FQDN is used with the wrong protocol', () => {
    configure({ fqdn: 'zammad.org', alternative_fqdn: 'localhost:3000', http_type: 'https' })

    detectUnknownAddress()

    useNotifications().notifications.value[0].actionCallback?.()

    expect(navigateTo).toHaveBeenCalledWith('https://zammad.org/')
  })

  it('keeps the current protocol when no HTTP type is configured', () => {
    configure({ fqdn: 'zammad.org', http_type: null })

    detectUnknownAddress()

    useNotifications().notifications.value[0].actionCallback?.()

    expect(navigateTo).toHaveBeenCalledWith('http://zammad.org/')
  })

  it('survives a login attempt or logout clearing all notifications', () => {
    configure({ fqdn: 'zammad.org', http_type: 'https' })

    detectUnknownAddress()

    const { notifications, clearAllNotifications } = useNotifications()

    clearAllNotifications()

    expect(notifications.value).toHaveLength(1)
    expect(notifications.value[0].id).toBe('unknown-fqdn-redirect')
  })

  it('warns again after the config was reloaded', async () => {
    configure({ fqdn: 'zammad.org', http_type: 'https' })

    detectUnknownAddress()

    const { notifications } = useNotifications()

    useApplicationStore().config = {} as ConfigList
    await nextTick()

    expect(notifications.value).toHaveLength(0)

    configure({ fqdn: 'zammad.org', http_type: 'https' })
    await nextTick()

    expect(notifications.value).toHaveLength(1)
  })

  it('removes the warning once the address matches the configuration', async () => {
    configure({ fqdn: 'zammad.org', http_type: 'https' })

    detectUnknownAddress()

    const { notifications } = useNotifications()

    expect(notifications.value).toHaveLength(1)

    configure({ fqdn: 'localhost:3000', http_type: 'http' })
    await nextTick()

    expect(notifications.value).toHaveLength(0)
  })
})
