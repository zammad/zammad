<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonNotifications from '#shared/components/CommonNotifications/CommonNotifications.vue'
import useAuthenticationChanges from '#shared/composables/authentication/useAuthenticationUpdates.ts'

defineProps<{ testKey: number }>()

useAuthenticationChanges()
</script>

<template>
  <div>
    <CommonNotifications />
    <RouterView :key="testKey" />
  </div>
</template>
