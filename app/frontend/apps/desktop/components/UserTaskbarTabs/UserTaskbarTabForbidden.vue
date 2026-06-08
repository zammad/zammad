<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { useUserTaskbarTab } from '#desktop/composables/useUserTaskbarTab.ts'

import type { UserTaskbarTabEntityProps } from './types.ts'

const props = defineProps<UserTaskbarTabEntityProps>()

const { tabLinkInstance, taskbarTabActive } = useUserTaskbarTab(toRef(props, 'taskbarTab'))
</script>

<template>
  <CommonLink
    v-if="taskbarTabLink"
    ref="tabLinkInstance"
    v-tooltip="$t('You have insufficient rights to view this object.')"
    class="flex grow items-center gap-2 px-2 py-3 focus-visible-app-default group-hover/tab:bg-blue-600 hover:no-underline! group-hover/tab:dark:bg-blue-900"
    :class="{
      ['bg-blue-800! text-white']: taskbarTabActive,
      'rounded-lg!': !collapsed,
    }"
    :link="taskbarTabLink"
    internal
  >
    <CommonIcon name="x-lg" size="tiny" class="shrink-0 text-red-500" decorative />

    <CommonLabel
      class="block! truncate text-gray-300 group-hover/tab:text-white dark:text-neutral-400"
      :class="{
        'text-white!': taskbarTabActive,
      }"
    >
      {{ $t('Access denied') }}
    </CommonLabel>
  </CommonLink>
</template>
