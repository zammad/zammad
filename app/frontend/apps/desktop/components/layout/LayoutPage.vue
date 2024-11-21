<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'

import { EnumTaskbarEntityAccess } from '#shared/graphql/types.ts'
import type { ErrorOptions } from '#shared/router/error.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'

import CommonError from '#desktop/components/CommonError/CommonError.vue'
import LayoutMain from '#desktop/components/layout/LayoutMain.vue'
import LeftSidebarFooterMenu from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarFooterMenu.vue'
import LeftSidebarHeader from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader.vue'
import LayoutSidebar from '#desktop/components/layout/LayoutSidebar.vue'
import PageNavigation from '#desktop/components/PageNavigation/PageNavigation.vue'
import UserTaskbarTabs from '#desktop/components/UserTaskbarTabs/UserTaskbarTabs.vue'
import { useResizeGridColumns } from '#desktop/composables/useResizeGridColumns.ts'
import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'

const { activeTaskbarTabEntityAccess, activeTaskbarTabEntityKey } = storeToRefs(
  useUserCurrentTaskbarTabsStore(),
)

const route = useRoute()

const entityAccess = computed<Maybe<EnumTaskbarEntityAccess> | undefined>(
  (currentValue) => {
    return route.meta.taskbarTabEntityKey === activeTaskbarTabEntityKey.value
      ? activeTaskbarTabEntityAccess.value
      : currentValue
  },
)

// NB: Flag in the route metadata data does not seem to trigger an update all the time.
//   Due to this limitation, we need a way to force the re-computation in certain situations.
const pageError = computed(() => {
  if (!route.meta.taskbarTabEntity) return null

  // Check first for page errors, when the entity access is not undefined.
  if (entityAccess.value === undefined) return undefined

  switch (entityAccess.value) {
    case EnumTaskbarEntityAccess.Forbidden:
      return {
        statusCode: ErrorStatusCodes.Forbidden,
        title: __('Forbidden'),
        message:
          (route.meta.messageForbidden as string) ??
          __('You have insufficient rights to view this object.'),
      } as ErrorOptions
    case EnumTaskbarEntityAccess.NotFound:
      return {
        statusCode: ErrorStatusCodes.NotFound,
        title: __('Not Found'),
        message:
          (route.meta.messageNotFound as string) ??
          __(
            'Object with specified ID was not found. Try checking the URL for errors.',
          ),
      } as ErrorOptions
    case EnumTaskbarEntityAccess.Granted:
    default:
      return null
  }
})

const noTransition = ref(false)

const { userId } = useSessionStore()

const storageKeyId = `${userId}-left`

const {
  currentSidebarWidth,
  maxSidebarWidth,
  minSidebarWidth,
  gridColumns,
  collapseSidebar,
  resizeSidebar,
  expandSidebar,
  resetSidebarWidth,
} = useResizeGridColumns(storageKeyId)
</script>

<template>
  <div
    class="grid h-full max-h-full overflow-y-clip duration-100"
    :class="{ 'transition-none': noTransition }"
    :style="gridColumns"
  >
    <LayoutSidebar
      id="main-sidebar"
      :name="storageKeyId"
      :aria-label="$t('Main sidebar')"
      data-theme="dark"
      :style="{ colorScheme: 'dark' }"
      :current-width="currentSidebarWidth"
      :max-width="maxSidebarWidth"
      :min-width="minSidebarWidth"
      collapsible
      resizable
      no-scroll
      @collapse="collapseSidebar"
      @expand="expandSidebar"
      @resize-horizontal="resizeSidebar"
      @resize-horizontal-start="noTransition = true"
      @resize-horizontal-end="noTransition = false"
      @reset-width="resetSidebarWidth"
    >
      <template #default="{ isCollapsed }">
        <LeftSidebarHeader class="mb-2" :collapsed="isCollapsed" />
        <PageNavigation :collapsed="isCollapsed" />
        <UserTaskbarTabs :collapsed="isCollapsed" />
        <LeftSidebarFooterMenu :collapsed="isCollapsed" class="mt-auto" />
      </template>
    </LayoutSidebar>
    <div class="relative">
      <LayoutMain
        v-if="pageError"
        class="flex grow flex-col items-center justify-center gap-4 bg-blue-50 dark:bg-gray-800"
      >
        <CommonError :options="pageError" authenticated />
      </LayoutMain>
      <slot v-else-if="pageError !== undefined"><RouterView /></slot>
    </div>
  </div>
</template>
