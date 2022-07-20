<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { RouteLocationRaw } from 'vue-router'

defineProps<{
  link: RouteLocationRaw
}>()
</script>

<template>
  <div class="h-14 w-14 py-2 focus:outline-none">
    <CommonLink
      v-if="link"
      :link="link"
      class="flex h-full w-full items-center justify-center border-white/10 ltr:border-l ltr:pl-1 rtl:border-r rtl:pr-1"
      open-in-new-tab
    >
      <CommonIcon name="external" size="small" />
    </CommonLink>
  </div>
</template>
