<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <img
    class="w-40 h-40"
    v-bind:src="logoUrl"
    v-bind:alt="config.get('product_name') as string"
  />
</template>

<script setup lang="ts">
import useApplicationConfigStore from '@common/stores/application/config'
import { computed } from 'vue'

const assetsPath = '/assets/images'
const config = useApplicationConfigStore()

const logoUrl = computed(() => {
  const productLogo = config.get('product_logo') as string
  if (!productLogo) {
    return `${assetsPath}/logo.svg`
  }
  return `${assetsPath}/${productLogo}`
})
</script>
