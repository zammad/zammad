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
import DynamicInitializer from '@shared/components/DynamicInitializer/DynamicInitializer.vue'
import useAuthenticationChanges from '@shared/composables/useAuthenticationUpdates'
import CommonConfirmation from '@mobile/components/CommonConfirmation/CommonConfirmation.vue'

defineProps<{ testKey: number }>()

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

useAuthenticationChanges()
</script>

<template>
  <div>
    <CommonNotifications />
    <CommonConfirmation />
    <LayoutHeader v-if="showHeader" v-bind="header" :title="title" />
    <main data-test-id="appMain">
      <RouterView :key="testKey" />
    </main>
    <footer data-bottom-navigation />
    <DynamicInitializer name="dialog" />
  </div>
</template>
