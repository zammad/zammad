<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { UserTaskbarItemEntitySearch } from '#shared/graphql/types.ts'

import { useUserTaskbarTabLink } from '#desktop/composables/useUserTaskbarTabLink.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props =
  defineProps<UserTaskbarTabEntityProps<UserTaskbarItemEntitySearch>>()

const { tabLinkInstance, taskbarTabActive } = useUserTaskbarTabLink(
  toRef(props, 'taskbarTab'),
)

const currentTitle = computed(
  () =>
    props.context?.query ||
    props.taskbarTab.entity?.query ||
    __('Extended Search'),
)
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
      class="text-neutral-500"
      :class="{
        'text-white!': taskbarTabActive,
      }"
      size="small"
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
