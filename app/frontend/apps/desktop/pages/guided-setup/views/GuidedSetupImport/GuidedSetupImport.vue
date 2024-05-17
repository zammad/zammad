<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { provide, ref } from 'vue'

import { useForm } from '#shared/components/Form/useForm.ts'
import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'

import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'
import { provideImportSource } from '#desktop/pages/guided-setup/composables/useImportSource.ts'

import { useSetTitle } from '../../composables/useSetTitle.ts'
import { SYSTEM_SETUP_SYMBOL } from '../../composables/useSystemSetup.ts'

import type { SystemSetup } from '../../types/setup.ts'

const { title, setTitle } = useSetTitle()

provide<SystemSetup>(SYSTEM_SETUP_SYMBOL, {
  setTitle,
})

const { form } = useForm()
const { loading, debouncedLoading } = useDebouncedLoading()

provideImportSource({
  form,
  loading,
  debouncedLoading,
  onContinueButtonCallback: ref(undefined),
})
</script>

<template>
  <LayoutPublicPage box-size="medium" :title="title">
    <RouterView />
  </LayoutPublicPage>
</template>
