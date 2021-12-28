<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <img class="w-32 h-32" v-bind:src="logoUrl" v-bind:alt="altText" />
</template>

<script setup lang="ts">
import useApplicationConfigStore from '@common/stores/application/config'
import { computed, ComputedRef } from 'vue'

const assetsPath = '/assets/images'
const config = useApplicationConfigStore()

const logoUrl: ComputedRef<string> = computed(() => {
  const productLogo = config.get('product_logo') as string
  if (!productLogo) {
    return `${assetsPath}/logo.svg`
  }
  return `${assetsPath}/${productLogo}`
})

const altText = config.get('product_name') as string
</script>
