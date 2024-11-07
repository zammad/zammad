<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'

import { errorOptions } from '#shared/router/error.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import CommonError from '#desktop/components/CommonError/CommonError.vue'
import LayoutMain from '#desktop/components/layout/LayoutMain.vue'
import LayoutPage from '#desktop/components/layout/LayoutPage.vue'

const { authenticated } = storeToRefs(useAuthenticationStore())
</script>

<template>
  <component
    :is="authenticated ? LayoutPage : 'div'"
    :class="{ 'h-full': !authenticated }"
  >
    <LayoutMain
      class="flex grow flex-col items-center justify-center gap-4 bg-blue-50 dark:bg-gray-800"
    >
      <CommonError :options="errorOptions" :authenticated="authenticated" />
    </LayoutMain>
  </component>
</template>
