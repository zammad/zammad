// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { useUserCurrentPushSubscriptionAddMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentPushSubscriptionAdd.api.ts'
import { useUserCurrentPushSubscriptionDeleteMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentPushSubscriptionDelete.api.ts'
import UserError from '#shared/errors/UserError.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { forgetAllShownPushNotifications } from '#shared/sw/shownPushNotifications.ts'
import { isStandalone } from '#shared/utils/pwa.ts'
import {
  isAppleMobileDevice,
  isPushSupported,
  urlBase64ToUint8Array,
} from '#shared/utils/webPush.ts'

import { getServiceWorkerRegistration } from '#mobile/sw/registration.ts'

import type { PushNotificationState, PushNotificationUnavailableReason } from './types'

// Holds the push state of this device, not of a user, so it outlives a logout.

class PushServiceRejected extends Error {}

const isPushServiceRejection = (error: unknown) =>
  error instanceof UserError &&
  error.fieldErrors.some((fieldError) => fieldError.field === 'endpoint')

export const usePushNotificationsStore = defineStore(
  'pushNotifications',
  () => {
    const application = useApplicationStore()
    const session = useSessionStore()
    const { notify } = useNotifications()

    const serviceWorkerStatus = ref<'unknown' | 'missing' | 'installing' | 'active'>('unknown')
    const permission = ref<NotificationPermission>(
      isPushSupported() ? Notification.permission : 'denied',
    )
    const isSubscribed = ref(false)
    const isSubscriptionKnown = ref(false)
    const isLoading = ref(false)

    // Remembers that push was turned on here, to tell a subscription the device
    //   dropped on its own (expired) from one the user never had.
    const wasEnabledOnDevice = useLocalStorage('zammad-push-notifications-enabled', false)

    // iOS reports a permission turned off in its settings as not asked yet, but
    //   refuses a new request without asking, so it counts as blocked once push
    //   was on here. Turned on again, it is reported as granted.
    const isPermissionWithdrawn = computed(
      () => permission.value === 'default' && wasEnabledOnDevice.value && isAppleMobileDevice(),
    )

    const isRecipient = computed(() =>
      session.hasPermission('user_preferences.notifications+ticket.agent'),
    )

    // Browsers hide the push APIs without a secure connection, and iOS hides
    //   them in a Safari tab, so these are told apart before the feature test.
    // A browser whose push service the server does not accept, e.g. Edge on
    //   Android, which hands out endpoints of a removed service. Remembered for
    //   this session only, a browser update may bring a working service.
    const isRegistrationRejected = ref(false)

    const unavailableReason = computed<PushNotificationUnavailableReason | null>(() => {
      if (window.isSecureContext === false) return 'insecure-connection'
      if (isAppleMobileDevice() && !isStandalone()) return 'not-installed'
      if (!isPushSupported()) return 'unsupported-browser'
      if (!application.config.web_push_vapid_public_key) return 'not-configured'
      if (serviceWorkerStatus.value === 'missing') return 'service-worker-missing'
      if (serviceWorkerStatus.value === 'installing') return 'service-worker-installing'
      if (isRegistrationRejected.value) return 'push-service-rejected'

      return null
    })

    const canUsePushNotifications = computed(
      () => isRecipient.value && unavailableReason.value === null,
    )

    const state = computed<PushNotificationState>(() => {
      if (!isRecipient.value) return 'hidden'
      if (unavailableReason.value) return 'unavailable'
      if (permission.value === 'denied' || isPermissionWithdrawn.value) return 'denied'
      if (isSubscribed.value) return 'enabled'

      return isSubscriptionKnown.value && wasEnabledOnDevice.value ? 'expired' : 'disabled'
    })

    // enable() shows one toast for every kind of failure, so the handler stays quiet.
    const addMutation = new MutationHandler(useUserCurrentPushSubscriptionAddMutation(), {
      errorCallback: () => false,
    })

    const deleteMutation = new MutationHandler(useUserCurrentPushSubscriptionDeleteMutation(), {
      errorNotificationMessage: __('Push notifications could not be disabled.'),
    })

    const getSubscription = async () => {
      const registration = await getServiceWorkerRegistration()

      return registration?.pushManager.getSubscription() ?? null
    }

    let isWaitingForServiceWorker = false

    // A worker that is still installing downloads the whole app for offline use
    //   first, and push can only be subscribed once it is active.
    const checkServiceWorker = async () => {
      const registration = await getServiceWorkerRegistration()

      if (!registration) {
        serviceWorkerStatus.value = 'missing'
        return
      }

      if (registration.active) {
        serviceWorkerStatus.value = 'active'
        return
      }

      serviceWorkerStatus.value = 'installing'

      if (isWaitingForServiceWorker) return

      isWaitingForServiceWorker = true

      navigator.serviceWorker.ready
        .then(() => {
          serviceWorkerStatus.value = 'active'
        })
        .finally(() => {
          isWaitingForServiceWorker = false
        })
    }

    const registerSubscription = async (subscription: PushSubscription) => {
      const { endpoint, keys } = subscription.toJSON()

      if (!endpoint || !keys?.p256dh || !keys?.auth)
        // eslint-disable-next-line zammad/zammad-detect-translatable-string
        throw new Error('Incomplete push subscription.')

      try {
        await addMutation.send({
          input: { endpoint, keys: { p256dh: keys.p256dh, auth: keys.auth } },
        })
      } catch (error) {
        if (!isPushServiceRejection(error)) throw error

        // The browser would hand out the same endpoint again, so the
        //   subscription goes, and no start asks the server again.
        await subscription.unsubscribe()
        isSubscribed.value = false
        isRegistrationRejected.value = true

        throw new PushServiceRejected()
      }
    }

    // Reads the state of the device without asking the server, cheap enough for
    //   every return of the app, e.g. from the settings of the device.
    const refresh = async () => {
      if (!isPushSupported()) return null

      permission.value = Notification.permission

      await checkServiceWorker()

      if (!canUsePushNotifications.value) return null

      const subscription = permission.value === 'granted' ? await getSubscription() : null

      isSubscribed.value = !!subscription
      isSubscriptionKnown.value = true

      return subscription
    }

    // Re-registers the subscription of this browser, so the server holds the
    //   current keys, e.g. after the push service rotated them or another user
    //   logged in on this device.
    const sync = async () => {
      const subscription = await refresh()

      if (!subscription) return

      try {
        await registerSubscription(subscription)
      } catch (error) {
        if (error instanceof PushServiceRejected) return

        throw error
      }

      wasEnabledOnDevice.value = true
    }

    const enable = async () => {
      if (!canUsePushNotifications.value) return

      isLoading.value = true

      try {
        permission.value = await Notification.requestPermission()
        if (permission.value !== 'granted') return

        const registration = await getServiceWorkerRegistration()
        // eslint-disable-next-line zammad/zammad-detect-translatable-string
        if (!registration) throw new Error('No service worker registration.')

        const subscription =
          (await registration.pushManager.getSubscription()) ??
          (await registration.pushManager.subscribe({
            userVisibleOnly: true,
            applicationServerKey: urlBase64ToUint8Array(
              application.config.web_push_vapid_public_key,
            ),
          }))

        await registerSubscription(subscription)

        isSubscribed.value = true
        wasEnabledOnDevice.value = true
      } catch (error) {
        // The locked toggle names the reason.
        if (error instanceof PushServiceRejected) return

        console.error(error)

        notify({
          id: 'push-notifications-enable-failed',
          message: __('Push notifications could not be enabled.'),
          type: NotificationTypes.Error,
        })
      } finally {
        isLoading.value = false
      }
    }

    // Removes the device from the current user, but keeps the browser
    //   subscription, so the next login on this device only has to sync.
    const unregisterDevice = async () => {
      if (!isPushSupported()) return null

      const subscription = await getSubscription()

      if (subscription) {
        await deleteMutation.send({ endpoint: subscription.endpoint })
        await forgetAllShownPushNotifications()
      }

      isSubscribed.value = false
      wasEnabledOnDevice.value = false

      return subscription
    }

    const disable = async () => {
      isLoading.value = true

      try {
        const subscription = await unregisterDevice()

        await subscription?.unsubscribe()
      } finally {
        isLoading.value = false
      }
    }

    return {
      state,
      unavailableReason,
      isLoading,
      refresh,
      sync,
      enable,
      disable,
      unregisterDevice,
    }
  },
  {
    requiresAuth: false,
  },
)
