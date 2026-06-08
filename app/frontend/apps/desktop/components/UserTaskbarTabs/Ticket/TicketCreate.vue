<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { type UserTaskbarItemEntityTicketCreate } from '#shared/graphql/types.ts'

import { useUserTaskbarTab } from '#desktop/composables/useUserTaskbarTab.ts'
import { useTicketCreateTitle } from '#desktop/entities/ticket/composables/useTicketCreateTitle.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props = defineProps<UserTaskbarTabEntityProps<UserTaskbarItemEntityTicketCreate>>()

const { tabLinkInstance, taskbarTabActive } = useUserTaskbarTab(toRef(props, 'taskbarTab'))

const currentTitle = computed(() => {
  return (props.context?.formValues?.title || props.taskbarTab.entity?.title) as string
})

const currentArticleType = computed(() => {
  return (props.context?.formValues?.articleSenderType ||
    props.taskbarTab.entity?.createArticleTypeKey) as string
})

const { currentViewTitle } = useTicketCreateTitle(currentTitle, currentArticleType)
</script>

<template>
  <CommonLink
    v-if="taskbarTabLink"
    ref="tabLinkInstance"
    v-tooltip="currentViewTitle"
    class="flex grow items-center gap-2 px-2 py-3 group-hover/tab:bg-blue-600 hover:no-underline! group-hover/tab:dark:bg-blue-900"
    :class="{
      ['bg-blue-800! text-white']: taskbarTabActive,
      'group-focus-visible/link:text-white': collapsed,
      'rounded-lg!': !collapsed,
    }"
    :link="taskbarTabLink"
    internal
  >
    <CommonIcon
      class="shrink-0 text-stone-200 dark:text-neutral-500"
      :class="{
        'text-white!': taskbarTabActive,
      }"
      name="pencil"
      size="tiny"
      decorative
    />

    <CommonLabel
      class="block! truncate text-gray-300 group-hover/tab:text-white dark:text-neutral-400"
      :class="{
        'text-white!': taskbarTabActive,
      }"
    >
      {{ currentViewTitle }}
    </CommonLabel>
  </CommonLink>
</template>
