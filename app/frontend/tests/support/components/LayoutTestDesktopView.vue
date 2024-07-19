<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonNotifications from '#shared/components/CommonNotifications/CommonNotifications.vue'
import DynamicInitializer from '#shared/components/DynamicInitializer/DynamicInitializer.vue'
import useAuthenticationChanges from '#shared/composables/authentication/useAuthenticationUpdates.ts'

import { initializeConfirmationDialog } from '#desktop/components/CommonConfirmationDialog/initializeConfirmationDialog.ts'

defineProps<{ testKey: number }>()

useAuthenticationChanges()

initializeConfirmationDialog()
</script>

<template>
  <div id="app">
    <DynamicInitializer name="dialog" />
    <DynamicInitializer name="flyout" />
    <CommonNotifications />
    <RouterView :key="testKey" />
  </div>
</template>
