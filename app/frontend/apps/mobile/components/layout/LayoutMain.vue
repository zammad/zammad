<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { headerOptions as header } from '@mobile/composables/useHeader'
import { computed, ref, unref } from 'vue'
import { useRoute } from 'vue-router'
// import TransitionViewNavigation from '../transition/TransitionViewNavigation/TransitionViewNavigation.vue'
import { useStickyHeader } from '@shared/composables/useStickyHeader'
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
  <div class="flex h-full flex-col overflow-hidden">
    <LayoutHeader
      v-if="showHeader"
      ref="headerComponent"
      v-bind="header"
      :title="title"
      :style="stickyStyles.header"
    />
    <main
      :class="{ 'pb-14': showBottomNavigation }"
      :style="showHeader ? stickyStyles.body : {}"
    >
      <!-- let's see how it feels without transition -->
      <RouterView />
      <!-- TODO check when we will have more time -->
      <!-- <router-view #default="{ Component }">
        <TransitionViewNavigation>
          <component :is="Component" />
        </TransitionViewNavigation>
      </router-view> -->
    </main>
    <LayoutBottomNavigation v-if="showBottomNavigation" />
  </div>
</template>
