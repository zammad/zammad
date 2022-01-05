<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <CommonNotifications />
  <div
    class="min-h-screen min-w-screen bg-black text-white text-center text-sm antialiased font-sans select-none"
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
import { computed, watch } from 'vue'

const router = useRouter()
const route = useRoute()

const sessionId = useSessionIdStore()
const authenticated = useAuthenticatedStore()

useMetaTitle().initializeMetaTitle()

const applicationLoaded = useApplicationLoadedStore()
applicationLoaded.setLoaded()

const invalidatedSession = computed(() => {
  return !sessionId.value && authenticated.value
})

watch(invalidatedSession, () => {
  authenticated.clearAuthentication()

  router.replace({
    name: 'Login',
    params: {
      invalidatedSession: '1',
    },
  })
})

// Add a watcher for authenticated changes (e.g. login/logout in a other browser tab).
authenticated.$subscribe((mutation, state) => {
  if (state.value && !sessionId.value) {
    sessionId.checkSession().then((sessionId) => {
      if (sessionId && route.name === 'Login') {
        router.replace('/')
      }
    })
  } else if (!state.value && sessionId.value) {
    sessionId.value = null
    router.replace('login')
  }
})
</script>
