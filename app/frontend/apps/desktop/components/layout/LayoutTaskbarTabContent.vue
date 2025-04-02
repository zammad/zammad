<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onActivated, ref, watch } from 'vue'
import { useRoute } from 'vue-router'

import { EnumTaskbarEntityAccess } from '#shared/graphql/types.ts'
import type { ErrorOptions } from '#shared/router/error.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'

import CommonError from '#desktop/components/CommonError/CommonError.vue'
import LayoutMain from '#desktop/components/layout/LayoutMain.vue'
import {
  initializeCurrentTaskbarTab,
  provideCurrentTaskbarTab,
} from '#desktop/entities/user/current/composables/useTaskbarTab.ts'

import { cleanupRouteDialogs } from '../CommonConfirmationDialog/initializeConfirmationDialog.ts'

const { path: currentRoutePath, meta: currentRouteMeta } = useRoute()

// Remember the current taskbar entity key
const currentTaskbarEntityKey = ref(currentRouteMeta.taskbarTabEntityKey)

const {
  currentTaskbarTabEntityAccess,
  currentTaskbarTabId,
  ...currentTaskbarTabData
} = initializeCurrentTaskbarTab(currentTaskbarEntityKey.value)

onActivated(() => {
  if (!currentTaskbarEntityKey.value) {
    currentTaskbarEntityKey.value = currentRouteMeta.taskbarTabEntityKey
  }
})

watch(currentTaskbarTabId, (newCurrentTaskbarTabId) => {
  if (!newCurrentTaskbarTabId && currentTaskbarEntityKey) {
    currentTaskbarEntityKey.value = undefined
  }
})

const showContent = computed(() => {
  return !!(currentTaskbarTabId.value && currentTaskbarEntityKey.value)
})

watch(showContent, (newValue, oldValue) => {
  if (oldValue && !newValue) {
    cleanupRouteDialogs(currentRoutePath)
  }
})

// NB: Flag in the route metadata data does not seem to trigger an update all the time.
//   Due to this limitation, we need a way to force the re-computation in certain situations.
const pageError = computed(() => {
  if (!currentTaskbarEntityKey.value) return null

  // Check first for page errors, when the entity access is not undefined.
  if (currentTaskbarTabEntityAccess.value === undefined) return undefined

  switch (currentTaskbarTabEntityAccess.value) {
    case EnumTaskbarEntityAccess.Forbidden:
      return {
        statusCode: ErrorStatusCodes.Forbidden,
        title: __('Forbidden'),
        message:
          (currentRouteMeta.messageForbidden as string) ??
          __('You have insufficient rights to view this object.'),
      } as ErrorOptions
    case EnumTaskbarEntityAccess.NotFound:
      return {
        statusCode: ErrorStatusCodes.NotFound,
        title: __('Not Found'),
        message:
          (currentRouteMeta.messageNotFound as string) ??
          __(
            'Object with specified ID was not found. Try checking the URL for errors.',
          ),
      } as ErrorOptions
    case EnumTaskbarEntityAccess.Granted:
    default:
      return null
  }
})

provideCurrentTaskbarTab({
  currentTaskbarTabId,
  currentTaskbarEntityKey: currentTaskbarEntityKey.value,
  ...currentTaskbarTabData,
})
</script>

<template>
  <LayoutMain
    v-if="showContent && pageError"
    class="flex grow flex-col items-center justify-center gap-4 bg-blue-50 dark:bg-gray-800"
  >
    <CommonError :options="pageError" authenticated />
  </LayoutMain>
  <slot v-else-if="showContent && pageError !== undefined" />
  <div
    v-else
    class="flex h-full w-full grow flex-col bg-blue-50 dark:bg-gray-800"
  ></div>
</template>
