<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, nextTick, watch } from 'vue'
import { onBeforeRouteLeave, useRouter } from 'vue-router'

import { useAfterAuthPlugins } from '../after-auth/composable/useAfterAuthPlugins.ts'
import LoginFooter from '../components/LoginFooter.vue'
import LoginHeader from '../components/LoginHeader.vue'

import type { RouteLocationRaw } from 'vue-router'

const { currentPlugin, data } = useAfterAuthPlugins()

const finished = ref(false)

onBeforeRouteLeave(() => {
  if (!finished.value) return false
})

watch(
  () => currentPlugin.value?.name,
  (name) => {
    if (name) {
      finished.value = false
    }
  },
)

const router = useRouter()

// TODO 2023-05-17 Sheremet V.A. - call a query to get a possible next after auth handler
const redirect = async (route: RouteLocationRaw) => {
  finished.value = true
  await nextTick()
  return router.replace(route)
}
</script>

<template>
  <div class="flex h-full min-h-screen flex-col items-center px-6 pb-4 pt-6">
    <main data-test-id="loginAfterAuth" class="m-auto w-full max-w-md">
      <div class="flex grow flex-col justify-center">
        <div v-if="currentPlugin" class="my-5 grow">
          <LoginHeader :title="currentPlugin.title" />
          <component
            :is="currentPlugin.component"
            :data="data"
            @redirect="redirect"
          />
        </div>
      </div>
    </main>
    <LoginFooter />
  </div>
</template>
