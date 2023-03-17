// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, shallowRef } from 'vue'

export const isStandalone: boolean =
  (('standalone' in window.navigator &&
    window.navigator.standalone) as boolean) ||
  window.matchMedia('(display-mode: standalone)').matches

interface InstallEvent extends Event {
  prompt(): Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

const deferredPrompt = shallowRef<InstallEvent | null>(null)

export const usePWASupport = () => {
  const canInstallPWA = computed(() => deferredPrompt.value !== null)

  const installPWA = async () => {
    if (!deferredPrompt.value) return

    deferredPrompt.value.prompt()

    const { outcome } = await deferredPrompt.value.userChoice
    if (outcome === 'accepted') {
      deferredPrompt.value = null
    }
  }

  return {
    canInstallPWA,
    installPWA,
  }
}

export const registerPWAHooks = () => {
  // this only works in Chrome, for iOS Safari users have to do it manually
  // for iOS we are showing a short guide on how to do it
  window.addEventListener('beforeinstallprompt', (e) => {
    deferredPrompt.value = e as InstallEvent
  })
  window.addEventListener('appinstalled', () => {
    deferredPrompt.value = null
  })
}

if (import.meta.env.DEV) {
  import('./testSw')
}
