<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { provide, ref } from 'vue'

import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'
import type { BoxSizes } from '#desktop/components/layout/types.ts'

import { useSetTitle } from '../../composables/useSetTitle.ts'
import { SYSTEM_SETUP_SYMBOL } from '../../composables/useSystemSetup.ts'

import type { SystemSetup } from '../../types/setup.ts'

const { title, setTitle } = useSetTitle()

const boxSize = ref<BoxSizes>('medium')

const setBoxSize = (newBoxSize: BoxSizes) => {
  boxSize.value = newBoxSize
}

const hideFooter = ref(false)

const setHideFooter = (newHideFooter: boolean) => {
  hideFooter.value = newHideFooter
}

provide<SystemSetup>(SYSTEM_SETUP_SYMBOL, {
  setTitle,
  setBoxSize,
  setHideFooter,
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
