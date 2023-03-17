<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { RouteLocationRaw } from 'vue-router'

defineProps<{
  link: RouteLocationRaw
}>()
</script>

<template>
  <div
    class="flex h-full items-center border-white/10 focus:outline-none ltr:border-l ltr:pl-1 rtl:border-r rtl:pr-1"
  >
    <CommonLink
      v-if="link"
      :link="link"
      class="flex h-10 w-12 items-center justify-center"
      open-in-new-tab
    >
      <CommonIcon name="mobile-external-link" size="small" />
    </CommonLink>
  </div>
</template>
