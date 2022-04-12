<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import useApplicationStore from '@common/stores/application'
import { computed } from 'vue'

const assetsPath = '/assets/images'
const application = useApplicationStore()

const logoUrl = computed(() => {
  const productLogo = application.config.product_logo as string
  if (!productLogo) {
    return `${assetsPath}/logo.svg`
  }
  return `${assetsPath}/${productLogo}`
})
</script>

<template>
  <img
    class="h-40 w-40"
    v-bind:src="logoUrl"
    v-bind:alt="(application.config.product_name as string)"
  />
</template>
