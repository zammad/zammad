<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import useFormKitConfig from '#shared/composables/form/useFormKitConfig.ts'
import CommonNotifications from '#shared/components/CommonNotifications/CommonNotifications.vue'
import useAppMaintenanceCheck from '#shared/composables/useAppMaintenanceCheck.ts'
import useAuthenticationChanges from '#shared/composables/authentication/useAuthenticationUpdates.ts'
import useMetaTitle from '#shared/composables/useMetaTitle.ts'
import usePushMessages from '#shared/composables/usePushMessages.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import emitter from '#shared/utils/emitter.ts'
import { onBeforeMount, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

const authentication = useAuthenticationStore()

useMetaTitle().initializeMetaTitle()

const application = useApplicationStore()
onBeforeMount(() => {
  application.setLoaded()
})

useAppMaintenanceCheck()
usePushMessages()

// Add a check for authenticated changes (e.g. login/logout in a other
// browser tab or maintenance mode switch).
useAuthenticationChanges()

// We need to trigger a manual translation update for the form related strings.
const formConfig = useFormKitConfig()
useLocaleStore().$subscribe(() => {
  formConfig.locale = 'staticLocale'
})

// The handling for invalid sessions. The event will be emitted, when from the server a "NotAuthorized"
// response is received.
emitter.on('sessionInvalid', async () => {
  if (authentication.authenticated) {
    await authentication.clearAuthentication()

    router.replace({
      name: 'Login',
      query: {
        invalidatedSession: '1',
      },
    })
  }
})

// Initialize the ticket overview store after a valid session is present on
// the app level, so that the query keeps alive.
// watch(
//   () => session.initialized,
//   (newValue, oldValue) => {
//     if (!oldValue && newValue) {
//       useTicketOverviewsStore()
//     }
//   },
//   { immediate: true },
// )

onBeforeUnmount(() => {
  emitter.off('sessionInvalid')
})
</script>

<template>
  <template v-if="application.loaded">
    <CommonNotifications />
  </template>
  <RouterView v-if="application.loaded" />
</template>
