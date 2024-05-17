<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTimeoutFn } from '@vueuse/shared'
import { useRouter } from 'vue-router'

import GuidedSetupStatusMessage from '../../components/GuidedSetupStatusMessage.vue'
import { useSystemSetup } from '../../composables/useSystemSetup.ts'

const { setBoxSize, setHideFooter, setTitle } = useSystemSetup()

setBoxSize?.('medium')
setHideFooter?.(true)

setTitle(__('Setup Finished'))

const router = useRouter()

useTimeoutFn(() => {
  router.replace('/') // TODO: Use 'default_router' setting.
}, 3000)
</script>

<template>
  <GuidedSetupStatusMessage :message="__('Starting Zammad…')" />
</template>
