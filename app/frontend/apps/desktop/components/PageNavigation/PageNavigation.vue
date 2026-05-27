<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { nextTick, computed } from 'vue'
import { useRouter } from 'vue-router'

import { useSessionStore } from '#shared/stores/session.ts'
import emitter from '#shared/utils/emitter.ts'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import { SidebarName } from '#desktop/components/layout/useSidebarDisplay.ts'
import { sortedFirstLevelRoutes } from '#desktop/components/PageNavigation/firstLevelRoutes.ts'

import CommonButton from '../CommonButton/CommonButton.vue'

interface Props {
  collapsed?: boolean
}

//*
// IMPORTANT: This is just a temporary implementation please replace and adapt it later
// *//
defineProps<Props>()

const router = useRouter()

const { hasPermission } = useSessionStore()

const openSearch = () => {
  emitter.emit('expand-collapsed-content', SidebarName.Primary)
  nextTick(() => emitter.emit('focus-quick-search-field'))
}

const permittedRoutes = computed(() => {
  return sortedFirstLevelRoutes.filter((route) => {
    return hasPermission(route.meta.requiredPermission)
  })
})
</script>

<template>
  <div>
    <CommonSectionCollapse id="page-navigation" :title="__('Navigation')" :no-header="collapsed">
      <template #default="{ headerId }">
        <nav :aria-labelledby="headerId">
          <ul class="flex basis-full flex-col" :class="{ 'gap-1': collapsed }">
            <li class="flex justify-center">
              <CommonButton
                v-if="collapsed"
                class="shrink-0 text-neutral-400 hover:outline-blue-900"
                size="large"
                variant="neutral"
                :aria-label="$t('Open quick search')"
                icon="search"
                @click="openSearch"
              />
            </li>
            <li
              v-for="route in permittedRoutes"
              :key="route.path"
              class="flex justify-center"
              :class="{ 'not-last:mb-1.5': !collapsed }"
            >
              <CommonButton
                v-if="collapsed"
                class="shrink-0 text-neutral-400 focus-visible-app-default hover:outline-blue-900"
                size="large"
                variant="neutral"
                :icon="route.meta.icon"
                @click="router.push(route.path.replace(/:\w+/, ''))"
              />
              <CommonLink
                v-else
                class="flex grow gap-2 rounded-lg px-2 py-3 text-neutral-400 focus-visible-app-default hover:bg-blue-900 hover:text-white! hover:no-underline! focus-visible:rounded-lg!"
                :class="{
                  'bg-blue-800! text-white!': router.currentRoute.value.name === route.name, // $route.name is not detected by ts
                }"
                :link="route.path.replace(/\/:\w+/, '')"
                exact-active-class="bg-blue-800! w-full text-white!"
                internal
              >
                <CommonLabel
                  class="gap-2 text-sm! text-current!"
                  size="medium"
                  :prefix-icon="route.meta.icon"
                >
                  {{ $t(route.meta.title) }}
                </CommonLabel>
              </CommonLink>
            </li>
          </ul>
        </nav>
      </template>
    </CommonSectionCollapse>
  </div>
</template>
