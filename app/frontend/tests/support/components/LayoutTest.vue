<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  useHeader,
  headerOptions as header,
} from '@mobile/composables/useHeader'
import { computed, unref, watch } from 'vue'
import { useRoute } from 'vue-router'
import LayoutHeader from '@mobile/components/layout/LayoutHeader.vue'
import CommonNotifications from '@shared/components/CommonNotifications/CommonNotifications.vue'

const route = useRoute()

const title = computed(() => {
  return unref(header.value.title) || route.meta.title
})

watch(
  () => route.path,
  () => {
    // reset header
    useHeader({})
  },
)

const showHeader = computed(() => {
  return route.meta.hasHeader
})
</script>

<template>
  <div>
    <CommonNotifications />
    <LayoutHeader v-if="showHeader" v-bind="header" :title="title" />
    <main>
      <RouterView />
    </main>
  </div>
</template>
