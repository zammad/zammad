<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import TransitionViewNavigation from '../transition/TransitionViewNavigation/TransitionViewNavigation.vue'
import LayoutBottomNavigation from './LayoutBottomNavigation.vue'

const route = useRoute()

const showBottomNavigation = computed(() => {
  return route.meta.hasBottomNavigation
})
</script>

<template>
  <div class="flex h-full flex-col overflow-hidden">
    <main class="overflow-y-scroll" :class="{ 'pb-14': showBottomNavigation }">
      <router-view #default="{ Component }">
        <TransitionViewNavigation>
          <component :is="Component" />
        </TransitionViewNavigation>
      </router-view>
    </main>
    <LayoutBottomNavigation v-if="showBottomNavigation" />
  </div>
</template>
