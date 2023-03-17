// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { RegisterSWOptions } from './types'

// should service worker be updated automatically without a prompt
const auto = false
// should servicer worker be destroyed - should be used only if something went wrong
const autoDestroy = false

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
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const sw = window.sw!
    // to trigger "Need refresh" run in console: `sw.triggerUpdate()`
    sw.ontriggerupdate = () => {
      onNeedRefresh?.()
    }
    // you can disable service worker in development mode by running in console: pwa.enable()
    // you can enable service worker, it will point to /public/vite-dev/sw.js
    // don't forget to unregister service worker, when you are done in console: pwa.disable()
    if (!sw.isEnabled()) {
      return () => {
        console.log('Updating service worker...')
        window.location.reload()
      }
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

        setTimeout(() => window.location.reload(), 1000)
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
