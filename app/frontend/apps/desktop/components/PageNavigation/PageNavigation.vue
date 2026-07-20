<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { nextTick, computed } from 'vue'
import { useRouter } from 'vue-router'

import { useSessionStore } from '#shared/stores/session.ts'
import emitter from '#shared/utils/emitter.ts'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import { sortedFirstLevelRoutes } from '#desktop/components/PageNavigation/firstLevelRoutes.ts'

import CommonButton from '../CommonButton/CommonButton.vue'
import { SidebarName } from '../layout/types.ts'
import { useSidebarDisplay } from '../layout/useSidebarDisplay.ts'

interface Props {
  collapsed?: boolean
}

defineProps<Props>()

const router = useRouter()

const { hasPermission } = useSessionStore()

const { toggleSidebar } = useSidebarDisplay(SidebarName.Primary)

const openSearch = () => {
  toggleSidebar(false)
  nextTick(() => emitter.emit('focus-quick-search-field'))
}

const permittedRoutes = computed(() =>
  sortedFirstLevelRoutes.filter(
    (route) => hasPermission(route.meta.requiredPermission) && (route.meta.canAccess?.() ?? true),
  ),
)

// A first-level entry is active whenever the current route lives in its
//   subtree, not only on an exact name match — nested pages
const isRouteActive = (name: string) =>
  router.currentRoute.value.matched.some((record) => record.name === name)
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
                v-tooltip="$t('Open quick search')"
                class="shrink-0 text-neutral-400 hover:outline-blue-900"
                size="large"
                variant="neutral"
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
                  'bg-blue-800! text-white!': isRouteActive(route.name),
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
