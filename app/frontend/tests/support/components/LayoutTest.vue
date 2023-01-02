<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { headerOptions as header } from '@mobile/composables/useHeader'
import { computed, unref } from 'vue'
import { useRoute } from 'vue-router'
import LayoutHeader from '@mobile/components/layout/LayoutHeader.vue'
import CommonNotifications from '@shared/components/CommonNotifications/CommonNotifications.vue'
import DynamicInitializer from '@shared/components/DynamicInitializer/DynamicInitializer.vue'
import useAuthenticationChanges from '@shared/composables/useAuthenticationUpdates'
import CommonConfirmation from '@mobile/components/CommonConfirmation/CommonConfirmation.vue'
import CommonImageViewer from '@shared/components/CommonImageViewer/CommonImageViewer.vue'

defineProps<{ testKey: number }>()

const route = useRoute()

const title = computed(() => {
  return unref(header.value.title) || route.meta.title
})

const showHeader = computed(() => {
  return route.meta.hasHeader
})

const hasOwnLandmarks = computed(() => {
  return route.meta.hasOwnLandmarks
})

const mainContainer = computed(() => (hasOwnLandmarks.value ? 'div' : 'main'))

const footerContainer = computed(() =>
  hasOwnLandmarks.value ? 'div' : 'footer',
)

useAuthenticationChanges()
</script>

<template>
  <div>
    <LayoutHeader v-if="showHeader" v-bind="header" :title="title" />
    <component :is="mainContainer" data-test-id="appMain">
      <RouterView :key="testKey" />
    </component>
    <component :is="footerContainer" data-bottom-navigation />
    <DynamicInitializer name="dialog" />
    <CommonNotifications />
    <CommonImageViewer />
    <CommonConfirmation />
  </div>
</template>
