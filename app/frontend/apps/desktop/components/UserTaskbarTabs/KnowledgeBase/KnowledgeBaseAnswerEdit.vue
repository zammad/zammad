<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import {
  EnumKnowledgeBaseVisibility,
  type KnowledgeBaseAnswerTranslation,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import { visibilityMeta } from '#desktop/components/KnowledgeBaseAnswerIcon/visibilityMeta.ts'
import { useUserTaskbarTab } from '#desktop/composables/useUserTaskbarTab.ts'
import { taskbarTabLocaleCode } from '#desktop/entities/knowledge-base/utils/taskbarTabKey.ts'
import { isTranslationMissing } from '#desktop/entities/knowledge-base/utils/translationLocale.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

// The entity of an answer edit tab is the *translation* it edits, in the tab's own locale
//   (Gql::Types::User::TaskbarItemType#answer_translation): the answer is one object for every
//   locale's tab, and its title would be whichever locale loaded last. The schema type rather than
//   the tab's fragment, like the sibling tabs - a narrowed fragment is not assignable to
//   `UserTaskbarTabEntity`.
const props = defineProps<UserTaskbarTabEntityProps<KnowledgeBaseAnswerTranslation>>()

const { tabLinkInstance, taskbarTabActive } = useUserTaskbarTab(toRef(props, 'taskbarTab'))

// The locale this tab edits, out of its own key: one answer has a tab per translation.
const localeCode = computed(() => taskbarTabLocaleCode(props.taskbarTab.tabEntityKey))

// A translation that does not exist yet: the title this tab was handed belongs to the locale it
//   falls back to. Only once the entity is there - otherwise every tab in the list reads as missing
//   while its query is out.
const translationMissing = computed(
  () =>
    Boolean(props.taskbarTab.entity) &&
    isTranslationMissing(props.taskbarTab.entity, localeCode.value),
)

// The stored title, not the one being typed: a label following the form would rename the tab while
//   somebody is still deciding whether to save.
//
// Except while the translation is missing - there is no stored title in this locale, and the tab
//   would be labelled in another language. Then it follows the form like a create tab does, and
//   falls back to a name for a tab waiting in the list, which has no live form values.
const currentViewTitle = computed(() => {
  if (translationMissing.value)
    return (props.context?.formValues?.title as string | undefined) || i18n.t('Missing translation')

  return props.taskbarTab.entity?.title || i18n.t('Knowledge base answer')
})

// The stored visibility, not the one being updated: an icon following the form would mislead the
//   user that the change has already taken place, even though it's just a personal draft.
const currentVisibility = computed(
  () => props.taskbarTab.entity?.visibility || EnumKnowledgeBaseVisibility.Draft,
)

// The state's own color while the tab sits in the list, so the states are scannable there - and
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
