<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTimeoutFn } from '@vueuse/shared'
import { useRouter } from 'vue-router'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'

import { useSystemSetupManual } from '../../composables/useSystemSetupManual.ts'

const { setTitle } = useSystemSetupManual()

setTitle(__('Setup Finished'))

const router = useRouter()

useTimeoutFn(() => {
  router.replace('/') // TODO: Use 'default_router' setting.
}, 5000)
</script>

<template>
  <div class="text-center mt-1">
    <CommonLabel>
      {{ $t('Starting Zammad…') }}
    </CommonLabel>
    <CommonLoader class="mt-9 mb-3" loading />
  </div>
</template>
