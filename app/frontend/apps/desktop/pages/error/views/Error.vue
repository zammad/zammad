<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { errorOptions } from '#shared/router/error.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import CommonError from '#desktop/components/CommonError/CommonError.vue'
import LayoutMain from '#desktop/components/layout/LayoutMain.vue'

defineOptions({
  beforeRouteEnter(to) {
    // Keep the query, it tells the after guard to preserve error options set by a route guard.
    if (useAuthenticationStore().authenticated) return { path: '/error-tab', query: to.query }
    return true
  },
})
</script>

<template>
  <div class="h-full">
    <LayoutMain
      class="flex grow flex-col items-center justify-center gap-4 bg-blue-50 dark:bg-gray-800"
    >
      <CommonError :options="errorOptions" />
    </LayoutMain>
  </div>
</template>
