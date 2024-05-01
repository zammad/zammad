<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import TwoFactorConfigurationWizard from '#desktop/components/TwoFactor/TwoFactorConfigurationWizard.vue'

defineProps<{
  data?: unknown
}>()

const emit = defineEmits<{
  redirect: [url: string]
}>()

const redirect = (url: string) => {
  emit('redirect', url)
}
</script>

<template>
  <TwoFactorConfigurationWizard @redirect="redirect" />
</template>
