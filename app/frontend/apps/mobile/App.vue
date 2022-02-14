<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <CommonNotifications />
  <div
    class="min-w-full min-h-screen font-sans text-sm antialiased text-center text-white bg-black select-none"
  >
    <router-view v-if="applicationLoaded.value" />
  </div>
</template>

<script setup lang="ts">
import CommonNotifications from '@common/components/common/CommonNotifications.vue'
import useApplicationLoadedStore from '@common/stores/application/loaded'
import useAuthenticatedStore from '@common/stores/authenticated'
import useSessionIdStore from '@common/stores/session/id'
import useMetaTitle from '@common/composables/useMetaTitle'
import { useRoute, useRouter } from 'vue-router'
import emitter from '@common/utils/emitter'
import { onBeforeUnmount, onMounted, watch } from 'vue'
import useAppMaintenanceCheck from '@common/composables/useAppMaintenanceCheck'
import useApplicationConfigStore from '@common/stores/application/config'
import useSessionUserStore from '@common/stores/session/user'
import usePushMessages from '@common/composables/usePushMessages'
import useLocaleStore from '@common/stores/locale'
import useFormKitConfig from '@common/composables/useFormKitConfig'

const router = useRouter()
const route = useRoute()

const sessionId = useSessionIdStore()
const authenticated = useAuthenticatedStore()

useMetaTitle().initializeMetaTitle()

const applicationLoaded = useApplicationLoadedStore()
onMounted(() => {
  applicationLoaded.setLoaded()
})

useAppMaintenanceCheck()
usePushMessages()

// Add a watcher for authenticated changes (e.g. login/logout in a other browser tab).
authenticated.$subscribe(async (mutation, state) => {
  if (state.value && !sessionId.value) {
    sessionId.checkSession().then(async (sessionId) => {
      if (sessionId) {
        await authenticated.refreshAfterAuthentication()
      }

      if (route.name === 'Login') {
        router.replace('/')
      }
    })
  } else if (!state.value && sessionId.value) {
    await authenticated.clearAuthentication()
    router.replace('login')
  }
})

watch(
  () => useApplicationConfigStore().value.maintenance_mode,
  async (newValue, oldValue) => {
    if (
      !oldValue &&
      newValue &&
      useAuthenticatedStore().value &&
      !useSessionUserStore().hasPermission(['admin.maintenance', 'maintenance'])
    ) {
      await useAuthenticatedStore().logout()
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
  if (authenticated.value) {
    await authenticated.clearAuthentication()

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
