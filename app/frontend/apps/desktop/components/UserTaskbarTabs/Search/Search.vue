<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { UserTaskbarItemEntitySearch } from '#shared/graphql/types.ts'

import { useSearchTitle } from '#desktop/components/Search/composables/useSearchTitle.ts'
import { useUserTaskbarTab } from '#desktop/composables/useUserTaskbarTab.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props = defineProps<UserTaskbarTabEntityProps<UserTaskbarItemEntitySearch>>()

const { tabLinkInstance, taskbarTabActive } = useUserTaskbarTab(toRef(props, 'taskbarTab'))

const filterCount = computed<number>(() => props.taskbarTab.entity?.filterCount ?? 0)
const currentSearchTerm = computed(
  () => (props.context?.query as string) || props.taskbarTab.entity?.query || '',
)
const { searchTitle: currentTitle } = useSearchTitle(currentSearchTerm, filterCount)
</script>

<template>
  <CommonLink
    v-if="taskbarTabLink"
    ref="tabLinkInstance"
    class="flex grow items-center gap-2 rounded-md px-2 py-3 group-hover/tab:bg-blue-600 hover:no-underline! focus-visible:rounded-md focus-visible:outline-hidden group-hover/tab:dark:bg-blue-900"
    :link="taskbarTabLink"
    :class="{
      'bg-blue-800!': taskbarTabActive,
    }"
    internal
  >
    <CommonIcon
      class="shrink-0 text-neutral-500 group-focus-visible/link:text-white!"
      :class="{
        'text-white!': taskbarTabActive,
      }"
      size="tiny"
      name="search-detail"
    />
    <CommonLabel
      class="block! truncate text-gray-300 group-focus-visible/link:text-white dark:text-neutral-400 group-hover/tab:dark:text-white"
      :class="{
        'text-white!': taskbarTabActive,
      }"
    >
      {{ currentTitle }}
    </CommonLabel>
  </CommonLink>
</template>
