// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { describe } from 'vitest'
import { ref } from 'vue'

import { useBrowserNotifications } from '#shared/composables/useBrowserNotifications.ts'

let permission = vi.hoisted((): string | undefined => 'granted')

vi.mock('@vueuse/core', () => ({
  usePermission: () => ref(permission),
}))

describe('useBrowserNotifications', () => {
  it('should request granted notification permission', () => {
    const { requestNotification } = useBrowserNotifications()

    const requestPermissionSpy = vi.spyOn(Notification, 'requestPermission')

    requestNotification()

    expect(requestPermissionSpy).toHaveBeenCalled()
  })

  it('returns granted permission when requestNotification is called', async () => {
    const { requestNotification, isGranted } = useBrowserNotifications()

    await requestNotification()

    expect(isGranted.value).toBe(true)
  })

  it('has by default no notification permission', () => {
    permission = undefined
    // vi.restoreAllMocks ... does not work here
    const { notificationPermission, isGranted } = useBrowserNotifications()

    expect(notificationPermission.value).toBe(undefined)
    expect(isGranted.value).toBe(false)
  })
})
