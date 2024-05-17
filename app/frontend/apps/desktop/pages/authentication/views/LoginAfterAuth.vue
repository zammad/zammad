<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, nextTick, watch } from 'vue'
import { onBeforeRouteLeave, useRouter } from 'vue-router'

import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'

import { useAfterAuthPlugins } from '../after-auth/composable/useAfterAuthPlugins.ts'

import type { RouteLocationRaw } from 'vue-router'

defineOptions({
  beforeRouteEnter(to) {
    const { currentPlugin } = useAfterAuthPlugins()
    if (!currentPlugin.value) {
      return to.redirectedFrom ? false : '/'
    }
  },
})

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
  <LayoutPublicPage box-size="small" :title="currentPlugin?.title">
    <div class="m-auto w-full max-w-md">
      <div class="flex grow flex-col justify-center">
        <div v-if="currentPlugin" class="grow">
          <component
            :is="currentPlugin.component"
            :data="data"
            @redirect="redirect"
          />
        </div>
      </div>
    </div>
  </LayoutPublicPage>
</template>
