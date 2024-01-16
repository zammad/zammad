<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useLogoUrl } from '#shared/composables/useLogoUrl.ts'

const { logoUrl } = useLogoUrl()
</script>

<template>
  <img class="max-h-32 max-w-[14rem]" :src="logoUrl" :alt="$c.product_name" />
</template>
