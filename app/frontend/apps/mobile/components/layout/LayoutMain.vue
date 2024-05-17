<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, unref } from 'vue'
import { useRoute } from 'vue-router'

// import TransitionViewNavigation from '../transition/TransitionViewNavigation/TransitionViewNavigation.vue'
import { useStickyHeader } from '#shared/composables/useStickyHeader.ts'

import { headerOptions as header } from '#mobile/composables/useHeader.ts'

import LayoutBottomNavigation from './LayoutBottomNavigation.vue'
import LayoutHeader from './LayoutHeader.vue'

const route = useRoute()

const title = computed(() => {
  return unref(header.value.title) || route.meta.title
})

const showBottomNavigation = computed(() => {
  return route.meta.hasBottomNavigation
})

const showHeader = computed(() => {
  return route.meta.hasHeader
})

const headerComponent = ref<{ headerElement: HTMLElement }>()
const headerElement = computed(() => {
  return headerComponent.value?.headerElement
})

const { stickyStyles } = useStickyHeader([title], headerElement)
</script>

<template>
  <div class="flex h-full flex-col">
    <LayoutHeader
      v-if="showHeader"
      ref="headerComponent"
      v-bind="header"
      :title="title"
      :style="stickyStyles.header"
    />
    <main
      class="flex h-full flex-col"
      :style="showHeader ? stickyStyles.body : {}"
    >
      <!-- let's see how it feels without transition -->
      <RouterView />
      <div v-if="showBottomNavigation" class="BottomNavigationPadding"></div>
    </main>
    <LayoutBottomNavigation v-if="showBottomNavigation" />
  </div>
</template>

<style scoped>
.BottomNavigationPadding {
  @apply w-full shrink-0;

  height: calc(var(--safe-bottom, 0) + theme('height.14'));
}
</style>
