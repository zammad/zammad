<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useSystemSetupInfoStore } from '../stores/systemSetupInfo.ts'

defineOptions({
  async beforeRouteEnter(to) {
    const { authenticated } = useAuthenticationStore()
    const { hasPermission } = useSessionStore()

    if (authenticated && !hasPermission('admin.wizard')) {
      return { path: '/', replace: true }
    }

    await useSystemSetupInfoStore().setSystemSetupInfo()

    const systemSetupInfo = useSystemSetupInfoStore()
    if (systemSetupInfo.systemSetupDone) {
      return to.meta.requiresAuth ? true : { path: '/login', replace: true }
    }

    if (systemSetupInfo.redirectNeeded(to.path)) {
      return { path: systemSetupInfo.redirectPath, replace: true }
    }
  },
})
</script>

<template>
  <RouterView />
</template>
