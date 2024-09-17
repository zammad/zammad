<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, unref } from 'vue'
import { useRoute } from 'vue-router'

import CommonImageViewer from '#shared/components/CommonImageViewer/CommonImageViewer.vue'
import CommonNotifications from '#shared/components/CommonNotifications/CommonNotifications.vue'
import DynamicInitializer from '#shared/components/DynamicInitializer/DynamicInitializer.vue'
import useAuthenticationChanges from '#shared/composables/authentication/useAuthenticationUpdates.ts'

import CommonConfirmation from '#mobile/components/CommonConfirmation/CommonConfirmation.vue'
import LayoutHeader, {
  type Props as HeaderProps,
} from '#mobile/components/layout/LayoutHeader.vue'
import { headerOptions as header } from '#mobile/composables/useHeader.ts'

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
    <LayoutHeader
      v-if="showHeader"
      v-bind="header as HeaderProps"
      :title="title"
    />
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
