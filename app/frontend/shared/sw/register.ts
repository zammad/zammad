// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { RegisterSWOptions } from './types'

const auto = true
const autoDestroy = false

export type { RegisterSWOptions }

// eslint-disable-next-line sonarjs/cognitive-complexity
export const registerSW = (options: RegisterSWOptions) => {
  const {
    path,
    scope,
    immediate = false,
    onNeedRefresh,
    onOfflineReady,
    onRegistered,
    onRegisteredSW,
    onRegisterError,
  } = options

  // service worker is disabled during normal development
  if (import.meta.env.DEV) {
    // you can enable service worker, it will point to /public/vite-dev/sw.js
    // don't forget to unregister service worker, when you are done
    if (import.meta.env.VITE_SW_ENABLE) {
      navigator.serviceWorker.register(path, {
        scope,
        type: 'classic',
      })
    }
    return () => {
      // noop
    }
  }

  let wb: import('workbox-window').Workbox | undefined
  let registration: ServiceWorkerRegistration | undefined
  let registerPromise: Promise<void>
  let sendSkipWaitingMessage: () => Promise<void> | undefined

  const updateServiceWorker = async (reloadPage = true) => {
    await registerPromise
    if (!auto) {
      // Assuming the user accepted the update, set up a listener
      // that will reload the page as soon as the previously waiting
      // service worker has taken control.
      if (reloadPage) {
        wb?.addEventListener('controlling', (event) => {
          if (event.isUpdate) window.location.reload()
        })
      }

      await sendSkipWaitingMessage?.()
    }
  }

  const register = async () => {
    if (!('serviceWorker' in navigator)) {
      return
    }

    const { Workbox, messageSW } = await import('workbox-window')
    sendSkipWaitingMessage = async () => {
      if (registration && registration.waiting) {
        // Send a message to the waiting service worker,
        // instructing it to activate.
        // Note: for this to work, you have to add a message
        // listener in your service worker. See below.
        await messageSW(registration.waiting, { type: 'SKIP_WAITING' })
      }
    }
    wb = new Workbox(path, { scope, type: 'classic' })

    wb.addEventListener('activated', (event) => {
      // this will only controls the offline request.
      // event.isUpdate will be true if another version of the service
      // worker was controlling the page when this version was registered.
      if (event.isUpdate) {
        if (auto) window.location.reload()
      } else if (!autoDestroy) {
        onOfflineReady?.()
      }
    })

    if (!auto) {
      const showSkipWaitingPrompt = () => {
        // \`event.wasWaitingBeforeRegister\` will be false if this is
        // the first time the updated service worker is waiting.
        // When \`event.wasWaitingBeforeRegister\` is true, a previously
        // updated service worker is still waiting.
        // You may want to customize the UI prompt accordingly.

        // Assumes your app has some sort of prompt UI element
        // that a user can either accept or reject.
        onNeedRefresh?.()
      }

      // Add an event listener to detect when the registered
      // service worker has installed but is waiting to activate.
      wb.addEventListener('waiting', showSkipWaitingPrompt)
      // @ts-expect-error event listener provided by workbox-window
      wb.addEventListener('externalwaiting', showSkipWaitingPrompt)
    }

    // register the service worker
    wb.register({ immediate })
      .then((r) => {
        registration = r
        if (onRegisteredSW) onRegisteredSW(path, r)
        else onRegistered?.(r)
      })
      .catch((e) => {
        onRegisterError?.(e)
      })
  }

  registerPromise = register()

  return updateServiceWorker
}
