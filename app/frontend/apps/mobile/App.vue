<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonNotifications from '@common/components/common/CommonNotifications.vue'
import useApplicationStore from '@common/stores/application'
import useAuthenticationStore from '@common/stores/authentication'
import useSessionStore from '@common/stores/session'
import useMetaTitle from '@common/composables/useMetaTitle'
import { useRoute, useRouter } from 'vue-router'
import emitter from '@common/utils/emitter'
import { onBeforeUnmount, onMounted, watch } from 'vue'
import useAppMaintenanceCheck from '@common/composables/useAppMaintenanceCheck'
import usePushMessages from '@common/composables/usePushMessages'
import useLocaleStore from '@common/stores/locale'
import useFormKitConfig from '@common/composables/form/useFormKitConfig'

const router = useRouter()
const route = useRoute()

const session = useSessionStore()
const authentication = useAuthenticationStore()

useMetaTitle().initializeMetaTitle()

const application = useApplicationStore()
onMounted(() => {
  application.setLoaded()
})

useAppMaintenanceCheck()
usePushMessages()

// Add a watcher for authenticated changes (e.g. login/logout in a other browser tab).
authentication.$subscribe(async (mutation, state) => {
  if (state.authenticated && !session.id) {
    session.checkSession().then(async (sessionId) => {
      if (sessionId) {
        await authentication.refreshAfterAuthentication()
      }

      if (route.name === 'Login') {
        router.replace('/')
      }
    })
  } else if (!state.authenticated && session.id) {
    await authentication.clearAuthentication()
    router.replace('login')
  }
})

watch(
  () => application.config.maintenance_mode,
  async (newValue, oldValue) => {
    if (
      !oldValue &&
      newValue &&
      authentication.authenticated &&
      !session.hasPermission(['admin.maintenance', 'maintenance'])
    ) {
      await authentication.logout()
      router.replace('login')
    }
  },
)

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
  <CommonNotifications v-if="application.loaded" />
  <div
    v-if="application.loaded"
    class="min-h-screen min-w-full select-none bg-black font-sans text-sm text-white antialiased"
  >
    <router-view />
  </div>
</template>
