<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { nextTick, computed } from 'vue'
import { useRouter } from 'vue-router'

import { useSessionStore } from '#shared/stores/session.ts'
import emitter from '#shared/utils/emitter.ts'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import {
  navigationItemClass,
  navigationItemHighlightClass,
} from '#desktop/components/PageNavigation/navigationItemClasses.ts'
import {
  navigationItems,
  type NavigationItem,
  type PageRoute,
} from '#desktop/components/PageNavigation/navigationItems.ts'
import PageNavigationGroup from '#desktop/components/PageNavigation/PageNavigationGroup.vue'

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

const isRoutePermitted = (route: PageRoute) =>
  hasPermission(route.meta.requiredPermission) && (route.meta.canAccess?.() ?? true)

// Permissions are evaluated per route, so a group disappears as soon as none
//   of the routes targeting it are permitted.
const permittedItems = computed(() =>
  navigationItems.reduce<NavigationItem[]>((items, item) => {
    if (item.type === 'route') {
      if (isRoutePermitted(item.route)) items.push(item)
      return items
    }

    const routes = item.routes.filter(isRoutePermitted)
    if (routes.length) items.push({ ...item, routes })

    return items
  }, []),
)

// A main navigation entry is active whenever the current route lives in its
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
              v-for="item in permittedItems"
              :key="item.type === 'group' ? item.group.key : item.route.path"
              class="flex"
              :class="collapsed ? 'justify-center' : 'not-last:mb-1.5'"
            >
              <PageNavigationGroup
                v-if="item.type === 'group'"
                :group="item.group"
                :routes="item.routes"
                :collapsed="collapsed"
              />
              <CommonButton
                v-else-if="collapsed"
                v-tooltip="$t(item.route.meta.title)"
                class="shrink-0 text-neutral-400 focus-visible-app-default hover:outline-blue-900"
                size="large"
                variant="neutral"
                :icon="item.route.meta.icon"
                @click="router.push(item.route.path.replace(/:\w+/, ''))"
              />
              <CommonLink
                v-else
                class="hover:no-underline! focus-visible:rounded-lg!"
                :class="[
                  navigationItemClass,
                  { [navigationItemHighlightClass]: isRouteActive(item.route.name) },
                ]"
                :link="item.route.path.replace(/\/:\w+/, '')"
                :exact-active-class="`w-full ${navigationItemHighlightClass}`"
                internal
              >
                <CommonLabel
                  class="gap-2 text-sm! text-current!"
                  size="medium"
                  :prefix-icon="item.route.meta.icon"
                >
                  {{ $t(item.route.meta.title) }}
                </CommonLabel>
              </CommonLink>
            </li>
          </ul>
        </nav>
      </template>
    </CommonSectionCollapse>
  </div>
</template>
