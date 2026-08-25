<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import {
  EnumKnowledgeBaseVisibility,
  type UserTaskbarItemEntityKnowledgeBaseAnswerCreate,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import { visibilityMeta } from '#desktop/components/KnowledgeBaseAnswerIcon/visibilityMeta.ts'
import { useUserTaskbarTab } from '#desktop/composables/useUserTaskbarTab.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props =
  defineProps<UserTaskbarTabEntityProps<UserTaskbarItemEntityKnowledgeBaseAnswerCreate>>()

const { tabLinkInstance, taskbarTabActive } = useUserTaskbarTab(toRef(props, 'taskbarTab'))

// The title being typed comes from the live form context; the stored one from the draft state,
//   which is what a tab restored after a reload has. Neither exists for a tab that was just
//   opened, hence the static fallback.
const currentViewTitle = computed(() => {
  const title = (props.context?.formValues?.title || props.taskbarTab.entity?.title) as
    | string
    | undefined

  return title || i18n.t('New knowledge base answer')
})

// The same status icon a stored answer carries, so a draft is recognizable in the tab list. What
//   is picked in the form wins over what was stored on the last round trip; a tab that has never
//   had one shows the state it would be created in.
const currentVisibility = computed(
  () =>
    ((props.context?.formValues?.visibility as EnumKnowledgeBaseVisibility | undefined) ??
      props.taskbarTab.entity?.visibility) ||
    EnumKnowledgeBaseVisibility.Draft,
)

// The state's own colour while the tab sits in the list, so the states are scannable there - and
//   the active tab's white, which its blue background needs, once it is the one open.
const currentVisibilityIcon = computed(() => visibilityMeta[currentVisibility.value])
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
    :aria-current="isActive ? 'page' : undefined"
    :link="taskbarTabLink"
    internal
  >
    <CommonIcon
      class="shrink-0"
      :class="taskbarTabActive ? 'text-white!' : currentVisibilityIcon.class"
      :name="currentVisibilityIcon.icon"
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
