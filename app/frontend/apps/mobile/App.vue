<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onBeforeUnmount, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import CommonNotifications from '@shared/components/CommonNotifications/CommonNotifications.vue'
import useApplicationStore from '@shared/stores/application'
import useAuthenticationStore from '@shared/stores/authentication'
import useMetaTitle from '@shared/composables/useMetaTitle'
import emitter from '@shared/utils/emitter'
import useAppMaintenanceCheck from '@shared/composables/useAppMaintenanceCheck'
import usePushMessages from '@shared/composables/usePushMessages'
import useLocaleStore from '@shared/stores/locale'
import useFormKitConfig from '@shared/composables/form/useFormKitConfig'
import { useAppTheme } from '@shared/composables/useAppTheme'
import useAuthenticationChanges from '@shared/composables/useAuthenticationUpdates'
import DynamicInitializer from '@shared/components/DynamicInitializer/DynamicInitializer.vue'
import CommonConfirmation from '@mobile/components/CommonConfirmation/CommonConfirmation.vue'

const router = useRouter()

const authentication = useAuthenticationStore()

useMetaTitle().initializeMetaTitle()

const application = useApplicationStore()
onMounted(() => {
  // If Zammad was not properly set up yet, redirect to desktop front end.
  if (!application.config.system_init_done) {
    window.location.pathname = '/'
  } else {
    application.setLoaded()
  }
})

useAppMaintenanceCheck()
usePushMessages()
useAppTheme()

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
      params: {
        invalidatedSession: '1',
      },
    })
  }
})

onBeforeUnmount(() => {
  emitter.off('sessionInvalid')
})
</script>

<template>
  <template v-if="application.loaded">
    <CommonNotifications />
    <CommonConfirmation />
  </template>
  <div
    v-if="application.loaded"
    class="h-full min-w-full bg-black font-sans text-sm text-white antialiased"
  >
    <router-view />
  </div>
  <DynamicInitializer
    name="dialog"
    :transition="{
      enterActiveClass: 'duration-300 ease-out',
      enterFromClass: 'opacity-0 translate-y-3/4',
      enterToClass: 'opacity-100 translate-y-0',
      leaveActiveClass: 'duration-200 ease-in',
      leaveFromClass: 'opacity-100 translate-y-0',
      leaveToClass: 'opacity-0 translate-y-3/4',
    }"
  />
</template>
