<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { provide, ref } from 'vue'

import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'

import { SYSTEM_SETUP_MANUAL_SYMBOL } from '../../composables/useSystemSetupManual.ts'
import type { SystemSetupManual } from '../../types/setup-manual.ts'

const title = ref('')
const setTitle = (newTitle: string) => {
  title.value = newTitle
}

provide<SystemSetupManual>(SYSTEM_SETUP_MANUAL_SYMBOL, {
  setTitle,
})
</script>

<template>
  <LayoutPublicPage box-size="medium" :title="title">
    <RouterView />
  </LayoutPublicPage>
</template>
