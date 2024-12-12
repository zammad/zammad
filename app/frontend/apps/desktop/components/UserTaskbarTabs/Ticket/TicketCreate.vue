<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { type UserTaskbarItemEntityTicketCreate } from '#shared/graphql/types.ts'

import { useUserTaskbarTabLink } from '#desktop/composables/useUserTaskbarTabLink.ts'
import { useTicketCreateTitle } from '#desktop/entities/ticket/composables/useTicketCreateTitle.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props =
  defineProps<UserTaskbarTabEntityProps<UserTaskbarItemEntityTicketCreate>>()

const { tabLinkInstance } = useUserTaskbarTabLink()

const currentTitle = computed(() => {
  return (props.context?.formValues?.title ||
    props.taskbarTab.entity?.title) as string
})

const currentArticleType = computed(() => {
  return (props.context?.formValues?.articleSenderType ||
    props.taskbarTab.entity?.createArticleTypeKey) as string
})

const { currentViewTitle } = useTicketCreateTitle(
  currentTitle,
  currentArticleType,
)
</script>

<template>
  <CommonLink
    v-if="taskbarTabLink"
    ref="tabLinkInstance"
    v-tooltip="currentViewTitle"
    class="flex grow gap-2 rounded-md px-2 py-3 hover:no-underline focus-visible:rounded-md focus-visible:outline-none group-hover/tab:bg-blue-600 group-hover/tab:dark:bg-blue-900"
    :link="taskbarTabLink"
    exact-active-class="!bg-blue-800 text-white"
    internal
  >
    <CommonIcon
      class="-:text-stone-200 -:dark:text-neutral-500 shrink-0 group-focus-visible/link:text-white"
      name="pencil"
      size="small"
      decorative
    />

    <CommonLabel
      class="-:text-gray-300 -:dark:text-neutral-400 block truncate group-hover/tab:text-white group-focus-visible/link:text-white"
    >
      {{ currentViewTitle }}
    </CommonLabel>
  </CommonLink>
</template>

<style scoped>
.router-link-active {
  @apply text-white;

  .icon,
  span {
    @apply text-white;
  }
}
</style>
