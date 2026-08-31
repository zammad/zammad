<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import {
  EnumKnowledgeBaseVisibility,
  type KnowledgeBaseAnswerTaskbarTabAttributesFragment,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import { visibilityMeta } from '#desktop/components/KnowledgeBaseAnswerIcon/visibilityMeta.ts'
import { useUserTaskbarTab } from '#desktop/composables/useUserTaskbarTab.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props =
  defineProps<UserTaskbarTabEntityProps<KnowledgeBaseAnswerTaskbarTabAttributesFragment>>()

const { tabLinkInstance, taskbarTabActive } = useUserTaskbarTab(toRef(props, 'taskbarTab'))

// The stored title, not the one being typed: this tab belongs to the answer, and a label that
//   followed the form would rename the tab while somebody is still deciding whether to save at
//   all. It is what the taskbar query resolves for the answer (primary-locale, since that query
//   sets no locale). The static fallback covers the moment before it is available - and an answer
//   without a single translation, which has no name of its own to show.
const currentViewTitle = computed(
  () => props.taskbarTab.entity?.title || i18n.t('Knowledge base answer'),
)

// The same status icon the reader and the create draft show, so the state carries over between
//   all three. What is picked in the form wins over what was last stored; before either has
//   resolved there is nothing to show but a neutral placeholder.
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
