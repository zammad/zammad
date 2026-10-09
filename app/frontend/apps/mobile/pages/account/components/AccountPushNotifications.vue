<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'

import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import { usePushNotificationsStore } from '#mobile/entities/user/current/stores/pushNotifications.ts'
import type { PushNotificationUnavailableReason } from '#mobile/entities/user/current/stores/types.ts'

const pushNotifications = usePushNotificationsStore()

// The user may have changed the browser permission since the last visit.
onMounted(() => {
  pushNotifications.refresh().catch(console.error)
})

const variants = {
  true: __('yes'),
  false: __('no'),
}

const unavailableHelp: Record<PushNotificationUnavailableReason, string> = {
  'insecure-connection': __(
    'Push notifications need a secure connection. Open this app via HTTPS.',
  ),
  'not-installed': __(
    'Push notifications are only available after adding this app to the home screen.',
  ),
  'unsupported-browser': __('This browser does not support push notifications.'),
  'not-configured': __(
    'Push notifications are not set up on this system. Please contact your administrator.',
  ),
  'service-worker-missing': __(
    'Push notifications are not available because the app is not fully loaded. Please reload the app.',
  ),
  'service-worker-installing': __(
    'Push notifications become available once the app has finished loading. This can take a moment.',
  ),
  'push-service-rejected': __('This browser cannot register for push notifications.'),
}

const help = computed(() => {
  if (pushNotifications.unavailableReason)
    return unavailableHelp[pushNotifications.unavailableReason]

  switch (pushNotifications.state) {
    case 'denied':
      return __('Notifications are turned off for this app in the settings of this device.')
    case 'expired':
      return __(
        'Push notifications stopped working on this device. Turn them on again to keep receiving them.',
      )
    case 'enabled':
      return __('You get notified on this device about updates to your tickets.')
    default:
      return __('Turn on to get notified on this device about updates to your tickets.')
  }
})

const isEnabled = computed(() => pushNotifications.state === 'enabled')

const isLocked = computed(() => ['unavailable', 'denied'].includes(pushNotifications.state))

// FormKit flips the toggle on click regardless of the model value, so it is
//   remounted after every attempt and every change of the state, to show the
//   state that was really reached.
const toggleKey = ref(0)

// The toggle also reports a state it is merely shown, e.g. after a change in
//   the settings of the device, which must not switch anything.
const toggle = async (enabled: unknown) => {
  if (enabled === isEnabled.value) return

  // A tap while the last one is still running is ignored instead of locking
  //   the toggle, which would make it flicker on every change.
  if (pushNotifications.isLoading) {
    toggleKey.value += 1
    return
  }

  if (isEnabled.value) {
    await pushNotifications.disable()
  } else {
    await pushNotifications.enable()
  }

  toggleKey.value += 1
}
</script>

<template>
  <CommonSectionMenu
    v-if="pushNotifications.state !== 'hidden'"
    :header-label="__('Notifications')"
    :help="help"
  >
    <!-- Currently only modelValue is working: https://github.com/formkit/formkit/issues/629 -->
    <FormKit
      :key="`${pushNotifications.state}-${toggleKey}`"
      type="toggle"
      :model-value="isEnabled"
      :label="__('Push notifications on this device')"
      :variants="variants"
      :disabled="isLocked"
      :outer-class="{ 'px-3!': true }"
      wrapper-class="px-0!"
      @input-raw="toggle"
    />
  </CommonSectionMenu>
</template>
