<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import useApplicationStore from '@shared/stores/application'

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
  <img class="h-40 w-40" :src="logoUrl" :alt="($c.product_name as string)" />
</template>
