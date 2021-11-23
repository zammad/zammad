<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <CommonNotifications />
  <div
    class="
      min-h-screen min-w-screen
      bg-dark
      text-gray-400 text-center text-sm
      antialiased
      font-sans
      select-none
    "
  >
    <router-view v-if="applicationLoaded.value" v-slot="{ Component }">
      <transition>
        <component v-bind:is="Component" />
      </transition>
    </router-view>
  </div>
</template>

<script setup lang="ts">
import CommonNotifications from '@common/components/common/CommonNotifications.vue'
import useApplicationLoadedStore from '@common/stores/application/loaded'
import useAuthenticatedStore from '@common/stores/authenticated'
import useSessionIdStore from '@common/stores/session/id'
import { useRoute, useRouter } from 'vue-router'

// TODO ... maybe show some special message, if the session was removed from a other place.
// unauthorized () {
//     return !this.$store.getters.accessToken && this.$store.getters.authenticated;
// },

const router = useRouter()
const route = useRoute()

const sessionId = useSessionIdStore()
const authenticated = useAuthenticatedStore()

const applicationLoaded = useApplicationLoadedStore()

applicationLoaded.setLoaded()

// Add a watcher for authenticated change.
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
