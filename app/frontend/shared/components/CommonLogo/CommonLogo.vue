<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useApplicationStore } from '#shared/stores/application.ts'

const application = useApplicationStore()

const logoUrl = computed(() => {
  return `/api/v1/system_assets/product_logo/${application.config.product_logo}`
})
</script>

<template>
  <img
    class="max-h-32 max-w-[14rem]"
    :src="logoUrl"
    :alt="$c.product_name as string"
  />
</template>
