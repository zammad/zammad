<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { provide, ref } from 'vue'

import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'

import type { BoxSizes } from '#desktop/components/layout/types.ts'
import { SYSTEM_SETUP_MANUAL_SYMBOL } from '../../composables/useSystemSetupManual.ts'
import type { SystemSetupManual } from '../../types/setup-manual.ts'

const title = ref('')

const setTitle = (newTitle: string) => {
  title.value = newTitle
}

const boxSize = ref<BoxSizes>('medium')

const setBoxSize = (newBoxSize: BoxSizes) => {
  boxSize.value = newBoxSize
}

const hideFooter = ref(false)

const setHideFooter = (newHideFooter: boolean) => {
  hideFooter.value = newHideFooter
}

provide<SystemSetupManual>(SYSTEM_SETUP_MANUAL_SYMBOL, {
  setBoxSize,
  setHideFooter,
  setTitle,
})
</script>

<template>
  <LayoutPublicPage
    :box-size="boxSize"
    :hide-footer="hideFooter"
    :title="title"
  >
    <RouterView />
  </LayoutPublicPage>
</template>
